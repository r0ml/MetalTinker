
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import AppKit
import MetalKit
import os

import AVFoundation

let thePixelFormat = MTLPixelFormat.bgra8Unorm_srgb // could be bgra8Unorm_srgb
// let theOtherPixelFormat = MTLPixelFormat.bgra8Unorm_srgb

let multisampleCount = 4

let numberOfRenderPasses = 4

let uniformId = 0
let kbuffId = 3
let computeBuffId = 15
let audioBuffId = 20
let fftBuffId = 24

let inputTextureId = 0
let renderInputId = 10
let renderOutputId = 30
let cubeId = 20
let renderedTextsId = 40
let videoId = 50
let webcamId = 60

var z : SIMD4<Float> = [0,0,0,0]

// This is for debugging -- the regular way doesn't work in so many cases
var myCaptureScope = MTLCaptureManager.shared().makeCaptureScope(device: device)

class FrameTimer : ObservableObject {
  @Published var shaderPlayerTime : String = ""
  @Published var shaderFPS : String = ""
}

func now() -> Double {
  return Double ( DispatchTime.now().uptimeNanoseconds / 1000 ) / 1000000.0
}

/** This class is responsible for rendering the MetalView (building the render pipeline) */
final class RenderManager : NSObject, MTKViewDelegate, ObservableObject, Identifiable {
  
  static let numberOfVideos = 3
  static let numberOfCubes = 3
  static let numberOfSounds = 4
  static let numberOfTexts = 10
  
  
  private var texQ = DispatchQueue(label: "render pass texture q")
  
  private var syncQ = DispatchQueue(label: "synchronization q");
  
  private var previewing : Bool = false;
  
  var frameTimer : FrameTimer
  
  var metalView : MTKView?
  
  var mySize : CGSize?
  
  public var id : String {
    return myName
  }
  
  
  @Published @objc var myRealName : String
  
  var myName : String
  
  /** the preview for the shader (for use in the list) is stored here */
  @Published var _previewImage : CGImage?
  
  @Published var isRunning : Bool = true
  
  var config : ConfigController!
  
  var uniformBuffer : MTLBuffer!
  
  var setup : RenderSetup
  
  var depthStencilState : MTLDepthStencilState?

  var renderPassDescriptor : MTLRenderPassDescriptor {
    get {
      if let rr = _renderPassDescriptor { return rr }
      _renderPassDescriptor = makeRenderPassDescriptor(label: "render output", size: self.mySize!)
      return _renderPassDescriptor!
    }
 }

  var _renderPassDescriptor : MTLRenderPassDescriptor?
  
  var videoTexture : [MTLTexture?] = Array(repeating: nil, count: numberOfVideos)
  @Published var videoThumbnail : [CGImage]
  
  var cubeTexture : [MTLTexture?] = Array(repeating: nil, count: numberOfCubes)
  
  var audioBuffer : [MTLBuffer?]
  var fftBuffer : [MTLBuffer?]
  var webcamTexture : MTLTexture?
  
  private var textureLoader = MTKTextureLoader(device: device)

  @Published var textureThumbnail : [CGImage]

  /** There are three times for a shader:
   the startTime is when the shader started running
   the currentTime is the time of the current frame
   the lastTime is the time of the last frame
   
   This is not (strictly speaking) true.  In the event of a pause, time keeps
   marching on, so that a "resume" will see the paused time included in the
   interval between currentTime and lastTime.  So, when a pause is resumed,
   the "lastTime" and "startTime" need to be advanced by the duration of the
   pause, so that the illusion of continuous time (with pauses) is maintained.
   
   Just in case I want to back out the amount of time that was spent "paused",
   I keep a running total of "pauseDuration"
   */
  
  var times = Times()
  
  static let semCount = 1
  var gpuSemaphore : DispatchSemaphore = DispatchSemaphore(value: semCount)
  
  var fpsSamples : [Double] = Array(repeating: 1.0/60.0 , count: 60)
  var fpsX : Int = 0
  
  var videoRecorder : MetalVideoRecorder?
  
  private static let previewQ : OperationQueue = {
    let q = OperationQueue() //    DispatchQueue(label: "preview")
    q.maxConcurrentOperationCount = 20
    return q
  }()
  
  static var brokenImage : NSImage = NSImage(named: "BrokenImage")!
  
  // =============================================================================================
  private var empty : CGImage

  static let numberOfTextures = 6

  init(_ s : String ) {
    myRealName = s
    
    myName = (s.filter { !":()[].".contains($0) }).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_").replacingOccurrences(of: "é", with: "e")
    
    
    frameTimer = FrameTimer()
    
    let ib = device.makeBuffer(length: 16, options: [.storageModeShared])
    audioBuffer = Array(repeating: ib, count: RenderManager.numberOfSounds)
    fftBuffer = Array(repeating: ib, count: RenderManager.numberOfSounds)
    
    setup = RenderSetup(myName)
    empty = NSImage(named: "camera")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    videoThumbnail = Array(repeating: empty, count: RenderManager.numberOfVideos)
    textureThumbnail = Array(repeating: empty, count: RenderManager.numberOfTextures)
    super.init()

    config = ConfigController(s, self)

    times.lastTime = now()
    times.currentTime = times.lastTime
    times.startTime = times.currentTime


    let depthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilDescriptor.depthCompareFunction = .less
    depthStencilDescriptor.isDepthWriteEnabled = true // I would like to set this to false for triangle blending
    depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!

  }
  
  func singleStep() {
    // this should only work when I'm paused
    var paused = now() - times.lastTime;
    
    // single step backwards if shift key is pressed
    if (NSEvent.modifierFlags.contains(.shift)) {
      paused += (1/60.0)
      setup.iFrame -= 2;
    } else {
      paused -= (1/60.0)
    }
    times.startTime += paused
    times.lastTime += paused
    
    self.draw(in: metalView!, singleStepping: true)
  }
  
  func play() {
    times.currentTime = now()
    let paused = times.currentTime - times.lastTime
    times.startTime += paused
    times.lastTime += paused
    
    let sw = (NSApp.delegate as! AppDelegate).shaderWindow
    NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: sw, queue: nil) { note in
      self.stop()
    }
    
  }
  
  func stop() {
    NotificationCenter.default.removeObserver(self)
  }
  
  func rewind(_ sender : Any? = nil) {
    let n = now()
    times.lastTime = n
    times.currentTime = n
    times.startTime = n
    setup.iFrame = -1
  }
  
  
  // ====================================================================================
  
  func setupCubes() -> String {
    let cz : [String] = config.cubeNames
    for (txtd, url) in cz.enumerated() {
      
      do {
        cubeTexture[txtd] = try textureLoader.newTexture(name: url, scaleFactor: 2, bundle: Bundle.main, options: [
          .SRGB: NSNumber(value: false),
          //               .textureUsage : NSNumber(value: 0),
          //               .cubeLayout : MTKTextureLoader.CubeLayout.vertical,
          //               .generateMipmaps : NSNumber(value: true)
          // .allocateMipmaps : true
        ])
        /*
         switch txtd {
         case 0: controller?.cube0?.image = p
         case 1: controller?.cube1?.image = p
         default:
         os_log("%s", type: .error, "cube \(txtd) greater than 1 is not implemented")
         }
         */
      } catch(let e) {
        let m = "failed to load cube \(url) in \(myName): \(e.localizedDescription)"
        os_log("*** %s ***", type: .error, m)
        return  m + "\n"
      }
    }
    return ""
  }
  
  /** when the window resizes ... */
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    if self.mySize?.width != size.width || self.mySize?.height != size.height {
      // print("got a size update \(mySize) -> \(size)")
      // FIXME:
      // self.makeRenderPassTextures(size: size)
      self.config.pipelinePasses.forEach { ($0 as? RenderPipelinePass)?.resize(size) }
    } else {
      // print("got a size update message when the size didn't change \(size)")
    }
    self.mySize = size;
    self.setup.mouseLoc = CGPoint(x: size.width / 2.0, y: size.height/2.0 )
  }


  // ================================================================================================
  
  // var colors : [NSColor] = []
  
  public func windowWillClose(_ notification: Notification) {
    os_log("%s", type:.debug, "will close")
  }
  

  
  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering
  func doRenderEncoder( // _ rpdx : MTLRenderPassDescriptor,  // the current render pass descriptor -- it either uses the MTKView property, or generates one for off-screen rendering
    _ stat : Bool,
    _ xview : MTKView?,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    _ f : ((MTLTexture?) -> ())? ) { // for off-screen renderings, use a callback function instead of a semaphore?

    if uniformBuffer == nil, let ms = mySize { // notInitialized
      uniformBuffer = config.doInitialization(true, config: config, size: ms)
      let m2 = setupCubes()
       if m2.isEmpty {
      } else {
        print(m2)
      }
    }
    
    var scale : CGFloat = 1
    
    if let viewx = xview {let eml = NSEvent.mouseLocation
      let wp = viewx.window!.convertPoint(fromScreen: eml)
      let ml = viewx.convert(wp, from: nil)
      
      if viewx.isMousePoint(ml, in: viewx.bounds) {
        setup.mouseLoc = ml
      }
      
      scale = xview?.window?.screen?.backingScaleFactor ?? 1
    }


    // Set up the command buffer for this frame
    let  commandBuffer = commandQueue.makeCommandBuffer()!
    commandBuffer.label = "Render command buffer for \(self.myName)"

    if config.pipelinePasses.isEmpty {
      config.setupPipelines(size: mySize!)
    }
    for (x, mm) in config.pipelinePasses.enumerated() {
      mm.makeEncoder(commandBuffer, scale, self, stat, x == 0)
    }

    // =========================================================================
    

    var rt : MTLTexture?

//    if let frpp = config.pipelinePasses.last as? RenderPipelinePass {
      rt = self.renderPassDescriptor.colorAttachments[0].resolveTexture //  frpp.resolveTextures.1

    // FIXME: what about a filter?
//  } else if let frpp = config.pipelinePasses.last as? FilterPipelinePass {
//      rt = frpp.texture
//    }

    // what I want here is the resolve texture of the last pipeline pass
    commandBuffer.addCompletedHandler{ commandBuffer in
      if let f = f {
        // print("resolved texture")
        //         f( rpd.colorAttachments[0].resolveTexture  )
        f(rt)
      }
    }


    if let v = xview, let c = v.currentDrawable {
      commandBuffer.present(c)
    } else {
      // this is where I wind up if it is a preview draw
      // print("didn't present drawable because did not get current drawable?")
      //      let blt = commandBuffer.makeBlitCommandEncoder()
      //      blt?.synchronize(resource: rpd.colorAttachments[0].resolveTexture!)
      //      blt?.endEncoding()
      // print("no current drawable -- did not present")
    }

    // If I do the "blit" thing, I'm going to have to wait for this frame to complete before starting the
    // next frame.
    
    // If I'm not doing the "blit" thing, I can pipeline frames
    
    // I should figure out which of these "blits" are necessary.
    // The shader currently does not signal which renderInputs are desired.
    
    
    // FIXME: this is where I set up the blit commands for output attachments back to render inputs.
    /*    let bce = commandBuffer.makeBlitCommandEncoder()!
     for i in 0..<numberOfRenderPasses {
     if let a = renderPassOutputs[i],
     let b = renderPassInputs[i] {
     bce.copy(from: a, to: b)
     }
     }
     bce.endEncoding()
     */
    
    // without this, I get complaints about UI on background thread when I attempt to debug
    DispatchQueue.main.async {
      commandBuffer.commit()
    }
  }

  func resetTarget(_ v : MTKView) {
    metalView = v;
    v.delegate = self
    config.resetTarget()
  }

  // this draws at a point in time to generate a preview
  func draw(size: CGSize, time: Double, _ f : @escaping (MTLTexture?) -> () ) {
    syncQ.sync(flags: .barrier) {
      times.currentTime = times.startTime + time
    }
    mySize = size
    doRenderEncoder(true, nil, f)
  }
  
  func draw(in viewx: MTKView) {
    // FIXME: Is this the best place to set the view?
    if metalView == nil {
      metalView = viewx
    }
    draw(in: viewx, singleStepping: false)
  }
  
  // this draws the current frame
  func draw(in viewx: MTKView, singleStepping: Bool) {
    if isRunning || singleStepping {
      
      // FIXME: sometimes I get trapped here!
      let gw = gpuSemaphore.wait(timeout: .now() + .microseconds(1000/60) )
      if gw == .timedOut {
        //        print("bailed")
        return }
      
      
      syncQ.sync(flags: .barrier) {
        times.lastTime = times.currentTime
        times.currentTime = now()
      }
      
      // calculate and display the Frames Per Second
      fpsSamples[fpsX] = times.currentTime - times.lastTime
      fpsX += 1
      if fpsX == fpsSamples.count { fpsX = 0 }
      let zz = fpsSamples.reduce(0, +)
      let t = Int(round(60.0 / zz))
      
      frameTimer.shaderFPS = String(t)
      
      // modifierFlags = NSEvent.modifierFlags
      let c = config.clearColor
      viewx.clearColor = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))

      let duration: TimeInterval = TimeInterval(times.currentTime - times.startTime)
      _ = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
      let d = Int(floor(duration))
      let seconds = d % 60
      let minutes = (d / 60) % 60
      let fd = String(format: "%0.2d:%0.2d", minutes, seconds); //   "%0.2d:%0.2d.%0.2d", minutes, seconds, ms)
      
      frameTimer.shaderPlayerTime = fd
      
      
      // FIXME: abort the whole execution if ....
      // if I get an error "Execution of then command buffer was aborted due to an error during execution"
      // in here, any calculations based on difference between this time and last time?
      if let _ = viewx.currentRenderPassDescriptor, let _ = mySize {
        
        // to get the running shader to match the preview?
        // rpd.colorAttachments[0].clearColor = viewx.clearColor

        // FIXME:

        self.doRenderEncoder(false, viewx ) { _ in
          // print("signal")
          self.videoRecorder?.writeFrame(forTexture: viewx.currentDrawable!.texture)
          self.gpuSemaphore.signal()
        }
      } else {
        self.isRunning = false // if I'm not going to set up the gpuSemaphore signal -- time to admit that I must be bailed
        self.gpuSemaphore.signal()
      }
    }
  }
  
  // =======================================================================================================
  // Generate Preview
  func shaderPreview(size: CGSize, success: @escaping (MTLTexture?)->() ) {
    draw(size: CGSize(width: size.width, height: size.height), time: 10, success)
  }
  
  func previewImage(_ jj : CGSize) ->  CGImage?  {
    if let p = _previewImage {
      return p }
    if previewing {
      return nil
    }
    previewing = true

    // globalQ.asyncAfter(deadline: DispatchTime.now()+DispatchTimeInterval.microseconds(50) ) {

    RenderManager.previewQ.addOperation {
      self.shaderPreview(size: jj) { (t : MTLTexture?) in
        guard let t = t,
          let cImg = CIImage(mtlTexture: t, options: [:]) else {
            os_log("shader preview finalization failed to get CIImage", type: .error)
            return
        }
        let im = cImg.cgImage
        DispatchQueue.main.async {
          self._previewImage = im
          self.previewing = false;
        }
      }
    }
    
    return nil // RenderManager.brokenImage
  }



  /*
   // FIXME: figure out how to do RENDER STRINGS
   */
  /*
   if let j = bufstruc.getStructArray("renderStrings") {
   // FIXME: since this is done for each frame, keep the previous frame values, and if they are unchanged,
   //        leave the textures alone
   for i in 0..<textTextures.count { textTextures[i] = nil}
   j.enumerated().forEach { c in
   let (a,b) = c
   textTextures[a] = self.processFontRender(a, b)
   }
   }
   */

  // I could possibly use the MTLHeap technique to generate a single heap with all resources
  public func processFontRender(_ tid : Int, _ m : MyMTLStruct ) -> MTLTexture? {
    var font : NSFont = NSFont.systemFont(ofSize: 48)
    if let k = m["font"]?.getString() ,
      let f = NSFontManager.shared.font(withFamily: k, traits: [], weight: 5, size: 48) {
      font = f
    }

    if let msg = m["msg"]?.getString(), !msg.isEmpty {
      //      print("rendering \(msg)")
      let attrs = [NSAttributedString.Key.font : font, .foregroundColor : NSColor.green, .backgroundColor : NSColor.clear]
      // let mj = NSAttributedString(string: msg, attributes: attrs)

      let mj = msg as NSString
      // let sizx = mj.size( withAttributes: attrs)

      //      let br = NSStringDrawingContext()

      let rect = mj.boundingRect(with: CGSize(width: -1, height: -1), options: [.usesFontLeading, .usesDeviceMetrics], attributes: attrs)
      let sizx = rect.size
      //    print("\(rect.size), \(br.totalBounds)")

      let siz = CGSize(width : ceil(sizx.width), height: ceil(sizx.height))

      let im = NSImage(size: siz)
      let imrep = NSBitmapImageRep.init(bitmapDataPlanes: nil, pixelsWide: Int(siz.width), pixelsHigh: Int(siz.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: Int(4*siz.width), bitsPerPixel: 32)!
      im.addRepresentation(imrep)

      im.lockFocus()
      //          im.drawTextInCurrentContext(msg, attr: attrs, paddingX: 0, paddingY: 0)
      mj.draw(with: CGRect(x: -rect.origin.x, y: -rect.origin.y, width: siz.width, height: siz.height), options: [.usesFontLeading, .usesDeviceMetrics], attributes: attrs )
      im.unlockFocus()
      let t = im.getTexture(MTKTextureLoader(device: device), flipped: true, mipmaps: false)
      return t
    }
    return nil
  }



}


func makeRenderPassTexture(_ nam : String, size: CGSize) -> (MTLTexture, MTLTexture, MTLTexture)? {
  let texd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
  texd.textureType = .type2DMultisample
  texd.usage = [.renderTarget]
  texd.sampleCount = multisampleCount
  texd.resourceOptions = .storageModePrivate

  let texi = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */ , width: Int(size.width), height: Int(size.height), mipmapped: true)
  texi.textureType = .type2D
  texi.usage = [.shaderRead]
  texi.resourceOptions = .storageModePrivate

  let texo = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
  texo.textureType = .type2D
  texo.usage = [.renderTarget, .shaderWrite, .shaderRead] // or just renderTarget -- the read is in case the texture is used in a filter
  texo.resourceOptions = .storageModePrivate

  if let p = device.makeTexture(descriptor: texd),
    let q = device.makeTexture(descriptor: texi),
    let r = device.makeTexture(descriptor: texo) {
    p.label = "render pass \(nam) multisample"
    q.label = "render pass \(nam) input"
    r.label = "render pass \(nam) output"
    //        swapQ.async {



    return (p, q, r)
  }
  return nil
}

fileprivate func makeRenderPassDescriptor(label : String, size canvasSize: CGSize) -> MTLRenderPassDescriptor {
  //------------------------------------------------------------
  // texture on device to be written to..
  //------------------------------------------------------------
  let ts = makeRenderPassTexture(label, size: canvasSize)!
  let texture = ts.0
  let resolveTextures = (ts.1, ts.2)

  let renderPassDescriptor = MTLRenderPassDescriptor()
  renderPassDescriptor.colorAttachments[0].texture = texture
  renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
  renderPassDescriptor.colorAttachments[0].resolveLevel = 0
  renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTextures.1 //  device.makeTexture(descriptor: xostd)
  renderPassDescriptor.colorAttachments[0].loadAction = .clear // .load
  //      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)


  // only if I need depthing?
  renderPassDescriptor.depthAttachment = makeDepthAttachmentDescriptor(size: canvasSize)

  return renderPassDescriptor
}
