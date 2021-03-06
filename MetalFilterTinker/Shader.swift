
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import AppKit
import MetalKit
import os
import AVFoundation

/*
 I have to split Shader into the Model for MetalViewState, and the model for the shader.
 MetalViewState is the singleton which manages the state of the metal view, and there is only one of those.

 Shader tracks the stuff which is different for different shaders.
 */

public let device = MTLCreateSystemDefaultDevice()!
public let commandQueue = device.makeCommandQueue()!


let thePixelFormat = MTLPixelFormat.bgra8Unorm_srgb // could be bgra8Unorm_srgb
// let theOtherPixelFormat = MTLPixelFormat.bgra8Unorm_srgb

let multisampleCount = 4

let uniformId = 2
let kbuffId = 3
let computeBuffId = 15

// This is for debugging -- the regular way doesn't work in so many cases
// var myCaptureScope = MTLCaptureManager.shared().makeCaptureScope(device: device)


/** This class is responsible for rendering the MetalView (building the render pipeline) */
final class Shader : NSObject, ObservableObject, Identifiable {

  static func == (lhs: Shader, rhs: Shader) -> Bool {
    return lhs.myName == rhs.myName
  }

  private var texQ = DispatchQueue(label: "render pass texture q")
    
 // private var previewing : Bool = false;
  
 
  var metalView : MTKView?
  
  
  public var id : String {
    return myName
  }
  
  
  @Published @objc var myRealName : String
  
  var myName : String
  
  /** the preview for the shader (for use in the list) is stored here */
  // @Published var _previewImage : CGImage?

  var config : ConfigController?
  
  
  var depthStencilState : MTLDepthStencilState?

  func renderPassDescriptor(_ mySize : CGSize) -> MTLRenderPassDescriptor {
      if let rr = _renderPassDescriptor { return rr }
      _renderPassDescriptor = makeRenderPassDescriptor(label: "render output", size: mySize)
      return _renderPassDescriptor!
  }

  var _renderPassDescriptor : MTLRenderPassDescriptor?
  
  var textureLoader = MTKTextureLoader(device: device)

//  @Published var textureThumbnail : [CGImage]

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
    
    // let ib = device.makeBuffer(length: 16, options: [.storageModeShared])

    empty = NSImage(named: "camera")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    super.init()

    DispatchQueue.global().async {
      self.config = ConfigController(s)
      self.config?.doInitialization()

      let depthStencilDescriptor = MTLDepthStencilDescriptor()
      depthStencilDescriptor.depthCompareFunction = .less
      depthStencilDescriptor.isDepthWriteEnabled = true // I would like to set this to false for triangle blending
      self.depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }

  }
  
  
  // ====================================================================================
  
/*
   func setupVideo() {
    let zv : [VideoSupport] = config.videoNames
    
    for (txtd, vidsup) in zv.enumerated() {
      let v = vidsup
      v.getThumbnail() { p in

        //textureQ.async {
        self.videoTexture[txtd] = try? self.textureLoader.newTexture(cgImage: p, options: [
          .SRGB: NSNumber(value: false)
            ,  .generateMipmaps: NSNumber(value: true)
          ])
//        }

//        self.videoTexture[txtd] = vidsup.getTexture()
        DispatchQueue.main.async {
          self.videoThumbnail[txtd] = p
        }
      }
    }
  }
  */

  // ================================================================================================
  
  // var colors : [NSColor] = []
  
  public func windowWillClose(_ notification: Notification) {
    os_log("%s", type:.debug, "will close")
  }



  func grabVideo(_ times : Times) {
    guard let config = config else { return } 
    for (i,v) in config.fragmentTextures.enumerated() {
      if let vs = v.video {
        config.fragmentTextures[i].texture = vs.readBuffer(times.currentTime) //     v.prepare(stat, currentTime - startTime)
      }
    }

  // load the current time webcam frame
  // webcamTexture =
    /*
stat ?
    try? self.textureLoader.newTexture(name: "webcam_still", scaleFactor: 1.0, bundle: Bundle.main, options: [ MTKTextureLoader.Option.SRGB : true
    ,   .textureStorageMode : NSNumber(value: MTLStorageMode.private.rawValue)
      ,   .generateMipmaps : NSNumber(value: true)
      ,   .origin :  /* MTKTextureLoader.Origin.flippedVertically : */
        MTKTextureLoader.Origin.bottomLeft
    ] ) : */
    // config.webcam?.prepare()

  }

  
  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering
  func doRenderEncoder( // _ rpdx : MTLRenderPassDescriptor,  // the current render pass descriptor -- it either uses the MTKView property, or generates one for off-screen rendering
    _ xview : MTKView?,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    delegate : MetalDelegate,
    _ f : ((MTLTexture?) -> ())? ) { // for off-screen renderings, use a callback function instead of a semaphore?

    guard let config = config else { return }

    if delegate.uniformBuffer == nil /*, let ms = mySize */ { // notInitialized
      delegate.uniformBuffer = config.uniformBuffer
      // setupVideo()
    }
    
    var scale : CGFloat = 1
    
    if let viewx = xview {let eml = NSEvent.mouseLocation
      let wp = viewx.window!.convertPoint(fromScreen: eml)
      let ml = viewx.convert(wp, from: nil)
      
      if viewx.isMousePoint(ml, in: viewx.bounds) {
        delegate.setup.mouseLoc = ml
      }
      
      scale = xview?.window?.screen?.backingScaleFactor ?? 1
    }


    // Set up the command buffer for this frame
    let  commandBuffer = commandQueue.makeCommandBuffer()!
    commandBuffer.label = "Render command buffer for \(self.myName)"
    
    // load the current time video frames
    
    // I've accidentally loaded up the textures during setup....


    if config.pipelinePasses.isEmpty {
      config.setupPipelines()
      config.pipelinePasses.forEach { if let z = $0 as? RenderPipelinePass { z.makeRenderTextures(delegate.mySize!) } }
    }
    for (x, mm) in config.pipelinePasses.enumerated() {
      mm.makeEncoder(commandBuffer, scale, x == 0, delegate: delegate)
    }

    // =========================================================================


    

    var rt : MTLTexture?

//    if let frpp = config.pipelinePasses.last as? RenderPipelinePass {
    rt = self.renderPassDescriptor(delegate.mySize!).colorAttachments[0].resolveTexture //  frpp.resolveTextures.1

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
    }
    
    // without this, I get complaints about UI on background thread when I attempt to debug
    DispatchQueue.main.async {
      commandBuffer.commit()
    }
  }

/*  func resetTarget(_ v : MTKView) {
    metalView = v
    v.isPaused = true
    v.delegate = nil
      v.delegate = self
      v.isPaused = false
 //   config.resetTarget()
  }
*/
  
/*  // this draws at a point in time to generate a preview
  func draw(size: CGSize, time: Double, _ f : @escaping (MTLTexture?) -> () ) {
    syncQ.sync(flags: .barrier) {
      times.currentTime = times.startTime + time
    }
    mySize = size
    doRenderEncoder(true, nil, f)
  }
*/
  
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

extension Shader {
  /** when the window resizes ... */
/*  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    if self.mySize?.width != size.width || self.mySize?.height != size.height {
      // print("got a size update \(mySize) -> \(size)")
      // FIXME:
      // self.makeRenderPassTextures(size: size)
      self.config.pipelinePasses.forEach { ($0 as? RenderPipelinePass)?.resize(size) }
    } else {
      // print("got a size update message when the size didn't change \(size)")
    }
    self.mySize = size;
  }
*/

  // this draws the current frame
  func draw(in viewx: MTKView, delegate : MetalDelegate) {
//    if metalView == nil {
//      metalView = viewx
//    }

    if let ccc = config {
      // modifierFlags = NSEvent.modifierFlags
      let c = ccc.clearColor
      // FIXME: set the clear color
//      viewx.clearColor = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))




      // FIXME: abort the whole execution if ....
      // if I get an error "Execution of then command buffer was aborted due to an error during execution"
      // in here, any calculations based on difference between this time and last time?
      if let _ = viewx.currentRenderPassDescriptor {

        // to get the running shader to match the preview?
        // rpd.colorAttachments[0].clearColor = viewx.clearColor

        // FIXME:

        self.doRenderEncoder(viewx, delegate : delegate ) { _ in
          // FIXME: this is the thing that will record the video frame
          // self.videoRecorder?.writeFrame(forTexture: viewx.currentDrawable!.texture)
          delegate.gpuSemaphore.signal()
        }
      } else {
//        self.isRunning = false // if I'm not going to set up the gpuSemaphore signal -- time to admit that I must be bailed
        delegate.gpuSemaphore.signal()
      }
    }
  }

}


