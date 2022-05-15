// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import MetalKit
import os
import AVFoundation
import SwiftUI
import SceneKit

class GenericShader : NSObject, Identifiable, ObservableObject {
  @Published var isRunningx : Bool = false
  @Published var isSteppingx : Bool = false
  
  var metadata : MTLRenderPipelineReflection!

  /// this is the clear color for alpha blending?
  var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )

  

  var myGroup : String {
    get { "Generators" }
  }
  
  public var id : String {
    return String("\(myGroup)+\(myName)")
  }
  
  /// Used by subclass for passing in video frames
  func setupFrame(_ times: Times) {
  }
  
  /// Used by subclass for passing in video frames
  func startRunning() {
  }
  
  /// Used by subclass for passing in video frames
  func stopRunning() {
  }
  
  var myName : String
  private var frameInitializeReflection : MTLComputePipelineReflection?
  var frameInitializePipelineState : MTLComputePipelineState?
  

  // Config Controller
  /// This buffer is known as in on the metal side
  var uniformBuffer : MTLBuffer?
  
  var pipelineState : MTLRenderPipelineState!
  
  // from Delegate
  var videoRecorder : MetalVideoRecorder?
  var times = Times()
  var frameTimer = FrameTimer()
  var fpsSamples : [Double] = Array(repeating: 1.0/60.0 , count: 60)
  var fpsX : Int = 0

  var iFrame : Int = -1

  //  var uniformBuffer : MTLBuffer!
  var setup = RenderSetup() // or RenderSetup

  var textureSize : CGSize?
  var renderPassDescriptor : MTLRenderPassDescriptor?
  
  let semCount = 1
  var gpuSemaphore : DispatchSemaphore = DispatchSemaphore(value: 1)

  var fragmentBuffers : [BufferParameter] = []

  var library : MTLLibrary

  required init(_ s : String, _ l : MTLLibrary ) {
    //    print("ShaderFilter init \(s)")
    
    myName = s
    library = l
    super.init()

    //    self.doInitialization()
  }
  
  
  //  var function = Function(myGroup)
  
  
  func finishCommandEncoding(_ renderEncoder : MTLRenderCommandEncoder ) {
    // end of vertex add
    
    renderEncoder.setRenderPipelineState(pipelineState)
    
    //    let c = controlBuffer.contents().assumingMemoryBound(to: ControlBuffer.self)
    
    
    
    // A filter render encoder takes a single instance of a rectangle (4 vertices) which covers the input.
    //    let t = Int(c.pointee.topology)
    //    if t >= 0 && t <= 3 {
    //      let topo : MTLPrimitiveType = [.point, .line, .triangle, .triangleStrip][t]
    
    renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1 )
    //  }
    
  }
  
  func specialInitialization() {
    let aa = metadata
    if let bb = aa?.fragmentArguments {
      processBuffers(bb)
    }
  }



  func processBuffers(_ bst : [MTLArgument] ) {
    for a in bst {
      if a.name != "in" && a.name != "uni",
         let b = BufferParameter(a, 0, id: fragmentBuffers.count + 10) {
        fragmentBuffers.append(b)
      }
    }
  }

  func justInitialization() {
  }

  func doInitialization( ) {
    let uniformSize : Int = MemoryLayout<Uniform>.stride
#if os(macOS) || targetEnvironment(macCatalyst)
    let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
#else
    let uni = device.makeBuffer(length: uniformSize, options: [])!
#endif
    
    /*    controlBuffer = device.makeBuffer(length: MemoryLayout<ControlBuffer>.stride, options: [.storageModeShared] )!
     let c = controlBuffer.contents().assumingMemoryBound(to: ControlBuffer.self)
     c.pointee.topology = 3
     c.pointee.vertexCount = 4
     c.pointee.instanceCount = 1
     */
    uni.label = "uniform"
    uniformBuffer = uni
    
    let vertexProgram = currentVertexFn(myGroup)
    let fragmentProgram = currentFragmentFn(myGroup)
    
    if let rpp = setupRenderPipeline(vertexFunction: vertexProgram, fragmentFunction: fragmentProgram) {
      (self.pipelineState, self.metadata, _) = rpp
    }
    
    justInitialization()

    // This has to come after the setupRenderPipeline -- because that is where the metadata comes from.
    // but if the specialInitialization needs to add more colorAttachments for lastFrame processing,
    // the pipelineState needs to be regenerated -- for which it would need the functions again -- or the renderPipelineDescriptor
    self.specialInitialization()
    
    frameInitialize()
    
  }
  
  
  func frameInitialize() {
    // await super.justInitialization()
    let nam = myName + "_FrameInitialize"
    guard let initializationProgram = functionMaps[myGroup]!.find( nam ) else {
      //      print("no frame initialization program for \(self.myName)")
      return
    }
    let cpld = MTLComputePipelineDescriptor()
    cpld.computeFunction = initializationProgram
    
    do {
      frameInitializePipelineState = try device.makeComputePipelineState(function: initializationProgram,
                                                                         options:[.argumentInfo, .bufferTypeInfo], reflection: &frameInitializeReflection)
    } catch(let e) {
      print("failed to create frame initialization pipeline state for \(myName): \(e.localizedDescription)")
    }
    
  }
  
  
  
  func currentVertexFn(_ s : String) -> MTLFunction? {
    let lun = "\(myName)______Vertex"
    if let z = functionMaps[s]!.find(lun) { return z }
    return functionMaps[s]!.find("flatVertexFn")!
  }
  
  
  func currentFragmentFn(_ s : String) -> MTLFunction? {
    let lun = "\(myName)______Fragment"
    if let z = functionMaps[s]!.find(lun) { return z }
    return functionMaps[s]!.find("passthruFragmentFn")!
  }
  
  
  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering
  func doRenderEncoder(
    _ kk : RSetup,
    _ cq : MTLCommandQueue?,
    _ xview : MTKView?,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    _ scene : SCNScene?,
    //    _ rpd : MTLRenderPassDescriptor,
    //    delegate : MetalDelegate,
    _ f : ((MTLTexture?) -> ())? ) { // for off-screen renderings, use a callback function instead of a semaphore?
      
      doMouseDetection(xview)
      if let xvv = xview {
        doRenderEncoder3(kk, cq, xvv, f)
      } else {
        doRenderEncoder2(kk, cq, scene, f)
      }
    }

  func doMouseDetection(_ xview : MTKView?) {
    // FIXME: what is this in iOS land?  What is it in mac land?
    
#if os(macOS)
    Task {

      await MainActor.run {
        var scale : Int = 1
        let eml = NSEvent.mouseLocation
        if let xvv = xview,
           let xww = xvv.window {
          let wp = xww.convertPoint(fromScreen: eml)
          let ml = xvv.convert(wp, from: nil)

          if xvv.isMousePoint(ml, in: xvv.bounds) {
            Task { await setup.setTouch(ml) }
          }
          scale = Int(xvv.window?.screen?.backingScaleFactor ?? 1)
        }
      }
    }
#endif
    
#if targetEnvironment(macCatalyst)
    if let xvv = xview {
      let ourEvent = CGEvent(source: nil)!
      let point = ourEvent.unflippedLocation
      let xscale =  xvv.window!.screen.scale // was scale
                                             //      let ptx = CGPoint(x: point.x / xscale, y: point.y / xscale)
                                             //


      let offs = (NSClassFromString("NSApplication")?.value(forKeyPath: "sharedApplication.windows._frame") as? [CGRect])![0]

      //      let offs = ws.value(forKeyPath: "_frame") as! CGRect
      //      let soff = ws.value(forKeyPath: "screen._frame") as! CGRect

      let loff = xvv.convert(CGPoint.zero, to: xvv.window!)
      let ptx = CGPoint(x: point.x - offs.minX, y: point.y - offs.minY )
      let lpoint = CGPoint(x: ptx.x - loff.x, y: ptx.y - loff.y)

      scale = Int(xscale)

      // I don't know why the 40 is needed -- but it seems to work
      let zlpoint = CGPoint(x: lpoint.x, y: lpoint.y - xvv.bounds.height - 40 )
      if zlpoint.x >= 0 && zlpoint.y >= 0 && zlpoint.x < xvv.bounds.width && zlpoint.y < xvv.bounds.height {
        Task { await setup.setTouch(zlpoint) }
      }
    }
#endif
  }
  
  func doRenderEncoder2( _ kk : RSetup, _ cq : MTLCommandQueue?,  _ scene: SCNScene?, _ f : ((MTLTexture?) -> ())? )  {

    // Set up the command buffer for this frame
    let cqq = cq ?? commandQueue
    beginFrame(cqq)

    let commandBuffer = cqq.makeCommandBuffer()!
    commandBuffer.label = "Render command buffer for \(self.myName)"
    
    

    
    // At this point:
    // If I am doing a multi-pass, then I must:
    // 1) create the render textures for the multiple passes
    // 2) create multiple render passes
    // 3) blit the outputs to inputs for the next frame (or swap the inputs and outputs
    
    
    // Reference to mySize here can trigger a data race with GenericShader.mtkView (when resizing / reinitializing a shader)
    let msiz = kk.mySize ?? CGSize(width: 100, height: 100)
    let rpd = makeRenderPassDescriptor(label: "appRenderPass", scale: multisampleCount, size: msiz, scene)
    // the rpd color attachments should have the right textures in them

    doRenderEncoder4(kk, commandBuffer, msiz, rpd)


    
    //    if let c = xview.currentDrawable {
    
    //      let kk = xview.currentRenderPassDescriptor!
    
    //      let rt = self.renderPassDescriptor(delegate.mySize!).colorAttachments[0].resolveTexture //  frpp.resolveTextures.1
    
    // =========================================================================
    // if feeding back output from previous frame to next frame:
    
    // ========================================================================
    
    // makeLastFrameTextures went here:
    // so I can
    // a) create the output texture (or have it passed in)
    // b) if I'm creating the texture then I have to assign it to the scene background or take it from the currentRnderPass / Drawable
    
    
    // what I want here is the resolve texture of the last pipeline pass
    commandBuffer.addCompletedHandler{ commandBuffer in
      if let f = f {
        // print("resolved texture")
        f( rpd.colorAttachments[0].resolveTexture  )
      }
    }
    //    commandBuffer.present(rpd.colorAttachments[0]!)
    commandBuffer.commit()
    //      commandBuffer.waitUntilCompleted()
  }
  
  func doRenderEncoder4(_ kk : RSetup, _ commandBuffer : MTLCommandBuffer, _ size : CGSize, _ rpd : MTLRenderPassDescriptor) {
    makeEncoder(kk, commandBuffer, multisampleCount, rpd)
  }
  
  func doRenderEncoder3(_ rsx : RSetup, _ cq : MTLCommandQueue?, _ xvv: MTKView, _ f : ((MTLTexture?) -> ())? )  {

    // Set up the command buffer for this frame

    let cqq = cq ?? commandQueue
    beginFrame(cqq)

    let commandBuffer = cqq.makeCommandBuffer()!
    commandBuffer.label = "Render command buffer for \(self.myName)"
    
    

    
    // At this point:
    // If I am doing a multi-pass, then I must:
    // 1) create the render textures for the multiple passes
    // 2) create multiple render passes
    // 3) blit the outputs to inputs for the next frame (or swap the inputs and outputs



    if let rpd = xvv.currentRenderPassDescriptor {

      // the rpd color attachments should have the right textures in them
      //    makeEncoder(commandBuffer, multisampleCount, rpd)

      if let c = xvv.currentDrawable,
         let kk = xvv.currentRenderPassDescriptor,
         c.texture != nil {

        //      let rt = self.renderPassDescriptor(delegate.mySize!).colorAttachments[0].resolveTexture //  frpp.resolveTextures.1

        let msiz = CGSize(width: c.texture.width, height: c.texture.height)

        doRenderEncoder4(rsx, commandBuffer, msiz, kk )
        // =========================================================================
        // if feeding back output from previous frame to next frame:

        // ========================================================================


        // makeLastFrameTextures went here:
        // so I can
        // a) create the output texture (or have it passed in)
        // b) if I'm creating the texture then I have to assign it to the scene background or take it from the currentRnderPass / Drawable


        // what I want here is the resolve texture of the last pipeline pass
        commandBuffer.addCompletedHandler{ commandBuffer in
          if let f = f {
            // print("resolved texture")
            f( rpd.colorAttachments[0].resolveTexture  )
          }
        }
        commandBuffer.present( c )
      }
    }
    commandBuffer.commit()
    //      commandBuffer.waitUntilCompleted()
  }
  
  
  func makeRenderPassDescriptor(label : String, scale: Int, size canvasSize: CGSize, _ scene : SCNScene?) -> MTLRenderPassDescriptor {
    //------------------------------------------------------------
    // texture on device to be written to..
    //------------------------------------------------------------
    if scene?.background.contents != nil && textureSize == canvasSize {
    } else {
      
      textureSize = canvasSize
      let (texture, resolveTexture) = makeRenderPassTexture(label, format: thePixelFormat, scale: scale, size: canvasSize)!
      scene?.background.contents = nil
      scene?.background.contents = resolveTexture
      
      let renderPassDescriptor = MTLRenderPassDescriptor()
      renderPassDescriptor.colorAttachments[0].texture = texture
      renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
      renderPassDescriptor.colorAttachments[0].resolveLevel = 0
      renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTexture //  device.makeTexture(descriptor: xostd)
      renderPassDescriptor.colorAttachments[0].loadAction = loadAction(0) // .clear // .load
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 0, green: 0, blue: 1, alpha: 1)

      self.renderPassDescriptor = renderPassDescriptor
    }
    
    // only if I need depthing?
    // renderPassDescriptor.depthAttachment = RenderPipelinePass.makeDepthAttachmentDescriptor(size: canvasSize)
    
    return renderPassDescriptor!
  }

  func loadAction(_ : Int) -> MTLLoadAction {
    return .clear
  }
  
  func makeRenderPassTexture(_ nam : String, format: MTLPixelFormat, scale: Int, size: CGSize) -> (MTLTexture, MTLTexture)? {

    // If I don't use multisampling, I only need one texture
    // This is the output texture
    let texd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
    texd.textureType = .type2DMultisample
    texd.usage = [.renderTarget]
    texd.sampleCount = scale
    texd.resourceOptions = .storageModePrivate
    
    // This is the resolve texture
    let texo = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
    texo.textureType = .type2D
    texo.usage = [ /* .renderTarget, .shaderWrite, */ .shaderRead] // or just renderTarget -- the read is in case the texture is used in a filter
    texo.resourceOptions = .storageModePrivate

    if let p = device.makeTexture(descriptor: texd),
       let r = device.makeTexture(descriptor: texo) {
      p.label = "render pass \(nam) multisample"
      r.label = "render pass \(nam) output"
      return (p, r)
    }
    return nil
  }
  
  
  
  
  
  
  /// =====================================================================================================================
  func setArguments(_ renderEncoder : MTLRenderCommandEncoder) {
    for b in fragmentBuffers {
      renderEncoder.setFragmentBuffer(b.buffer, offset: 0, index: b.index)
    }

  }

  func makeEncoder(_ kk : RSetup,
                   _ commandBuffer : MTLCommandBuffer,
                   _ scale : Int,
                   _ rpd : MTLRenderPassDescriptor
                   //                           delegate : MetalDelegate
  ) {
    
    // to get the running shader to match the preview?
    // FIXME: do I have clearColor?
    //    if let cc = rm.metalView?.clearColor {
    //      rpd.colorAttachments[0].clearColor = cc
    
    
    
    // FIXME: should this be a clear or load?
    rpd.colorAttachments[0].loadAction = loadAction(0) // .load
    rpd.colorAttachments[0].storeAction = .multisampleResolve
    rpd.colorAttachments[0].clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 1)

    //    }
    
    let sz = CGSize(width : rpd.colorAttachments[0].texture!.width, height: rpd.colorAttachments[0].texture!.height )
    iFrame += 1

    kk.setupUniform(iFrame: iFrame, size: sz, scale: scale, uniform: uniformBuffer!, times: times )


    fixme(rpd)

    // texture and resolveTexture size mismatch    during resize
    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder"
      
      renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: uniformId)

      setArguments(renderEncoder)


      self.finishCommandEncoding(renderEncoder)

      renderEncoder.endEncoding()
    }
  }

  func fixme(_ rpd : MTLRenderPassDescriptor) {
    
  }
  
  // =============================================================================================================================================
  
  // this draws the current frame
  func ddraw(_ cq : MTLCommandQueue?, _ viewx: MTKView?, _ scene : SCNScene? ) {
    // FIXME: set the clear color
    //      viewx.clearColor = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))
    
    // FIXME: abort the whole execution if ....
    // if I get an error "Execution of then command buffer was aborted due to an error during execution"
    // in here, any calculations based on difference between this time and last time?
    //    if let rpd = viewx.currentRenderPassDescriptor {
    
    // to get the running shader to match the preview?
    // rpd.colorAttachments[0].clearColor = viewx.clearColor

    Task {
      let kk = await RSetup(setup)

      self.doRenderEncoder(kk, cq, viewx, scene)
      { _ in
        // FIXME: this is the thing that will record the video frame
        // self.videoRecorder?.writeFrame(forTexture: viewx.currentDrawable!.texture)
        self.gpuSemaphore.signal()
      }
    }
    
    //  }
  }
  
  
  // =============================================================================================================================================

  
  func beginFrame(_ cqq : MTLCommandQueue) {
    if
      let fips = frameInitializePipelineState,
      let commandBuffer = cqq.makeCommandBuffer(),
      let computeEncoder = commandBuffer.makeComputeCommandEncoder()
    {
      commandBuffer.label = "Frame Initialize command buffer for \(self.myName)"
      computeEncoder.label = "frame initialization and defaults encoder \(self.myName)"
      computeEncoder.setComputePipelineState(fips)
      computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)



      setInitializationArguments(computeEncoder)


      let ms = MTLSize(width: 1, height: 1, depth: 1);
      computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
      computeEncoder.endEncoding()
      
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed
    }
    
    // at this point, the frame initialization (ctrl) buffer has been set
    // FIXME: I should probably add a compute buffer to hold values across frames?
  }

  func setInitializationArguments(_ computeEncoder : MTLComputeCommandEncoder) {
    // FIXME: 1) I could have threadgroups to handle the buffer.
    //  2) How do I sync up the frameInitializer arguments with the fragment arguments?
    for b in fragmentBuffers {
      computeEncoder.setBuffer(b.buffer, offset: 0, index: b.index)
    }
  }
  
  func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?) -> (MTLRenderPipelineState, MTLRenderPipelineReflection, MTLRenderPipelineDescriptor)? {
    // ============================================
    // this is the actual rendering fragment shader
    
    let psd = MTLRenderPipelineDescriptor()
    
    psd.vertexFunction = vertexFunction
    psd.fragmentFunction = fragmentFunction
    psd.colorAttachments[0].pixelFormat = thePixelFormat
    psd.isAlphaToOneEnabled = false
    psd.colorAttachments[0].isBlendingEnabled = true
    psd.colorAttachments[0].alphaBlendOperation = .add
    psd.colorAttachments[0].rgbBlendOperation = .add
    psd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha // I would like to set this to   .one   for some cases
    psd.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    psd.colorAttachments[0].destinationRGBBlendFactor =  .destinationAlpha //   doesBlend ? .destinationAlpha : .oneMinusSourceAlpha
    psd.colorAttachments[0].destinationAlphaBlendFactor = .destinationAlpha //   doesBlend ? .destinationAlpha : .oneMinusSourceAlpha
    
    psd.sampleCount = multisampleCount
    psd.inputPrimitiveTopology = .triangle
    
    if psd.vertexFunction != nil && psd.fragmentFunction != nil {
      do {
        var metadata : MTLRenderPipelineReflection?
        let res = try device.makeRenderPipelineState(descriptor: psd, options: [.argumentInfo, .bufferTypeInfo], reflection: &metadata)
        if let m = metadata {
          return (res, m, psd)
        }
      } catch let er {
        // let m = "Failed to create render render pipeline state for \(self.label), error \(er.localizedDescription)"
        os_log("%s", type:.error, er.localizedDescription)
        return nil
      }
    } else {
      os_log("vertex or fragment function missing for \(self.myName)")
    }
    return nil
  }

  func buildPrefView() -> [IdentifiableView] {
    doInitialization()
    return []
  }

}


extension GenericShader { // was from MetalDelegate
  
  // --------------------------
  
  func singleStep( ) {
    // this should only work when I'm paused
    
    var paused = now() - times.lastTime;
    
    // single step backwards if shift key is pressed
    
#if os(macOS)
    let shifted = NSEvent.modifierFlags.contains(.shift)
#else
    let shifted = false
#endif
    
    if shifted {
      paused += (1/60.0)
      iFrame -= 2
    } else {
      paused -= (1/60.0)
    }
    times.startTime += paused
    times.lastTime += paused

    Task {
      await MainActor.run {
        isRunningx = true
        isSteppingx = true
      }
    }
    //    self.draw(in: metalView!)
  }
  
  func play() {
    times.currentTime = now()
    let paused = times.currentTime - times.lastTime
    times.startTime += paused
    times.lastTime += paused
    
    //   shader.config.videoNames.forEach { $0.start() }

    Task {
      await MainActor.run {
        isRunningx = true
        isSteppingx = false
      }
    }
    startRunning()
  }
  
  func stop() {
    Task {
      await MainActor.run {
        isRunningx = false
        isSteppingx = true
        stopRunning()

        // config.webcam?.stopCapture()
        // config.videoNames.forEach { $0.pause() }

        NotificationCenter.default.removeObserver(self)
      }
    }
  }

  func rewind(_ sender : Any? = nil) {
    let n = now()
    times.lastTime = n
    times.currentTime = n
    times.startTime = n
    iFrame = -1
  }

  /// return false to abort
  func doRunning( /* _ view : MTKView */ ) -> Bool {

    // FIXME: sometimes I get trapped here!
    //      print("in gpusem", terminator: "" )
    let gw = gpuSemaphore.wait(timeout: .now() + .microseconds(1) /*    .microseconds(1000/60) */ )
    if gw == .timedOut {
      //      print("GPU timed out")
      return false }

    times.lastTime = times.currentTime
    times.currentTime = now()

    // calculate and display the Frames Per Second

    // FIXME: put me back
    // just this doubles the CPU requirement.
    // can I make the frameTimer update be more efficient?


    fpsSamples[fpsX] = times.currentTime - times.lastTime
    fpsX += 1
    if fpsX == fpsSamples.count { fpsX = 0 }

    if 0 == iFrame % 60 {

      let zz = fpsSamples.reduce(0, +)
      let t = Int(round(60.0 / zz))
      Task {
        await MainActor.run { frameTimer.shaderFPS = String(t) }
      }


      // format the time for display
      let duration: TimeInterval = TimeInterval(times.currentTime - times.startTime)
      _ = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
      let d = Int(floor(duration))
      let seconds = d % 60
      let minutes = (d / 60) % 60
      let fd = String(format: "%0.2d:%0.2d", minutes, seconds); //   "%0.2d:%0.2d.%0.2d", minutes, seconds, ms)
      Task {
        await MainActor.run { frameTimer.shaderPlayerTime = fd }
      }
    }

    setupFrame(times)
    return true
  }
}


extension GenericShader : MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    Task { await setup.setTouch( CGPoint(x: size.width / 2.0, y: size.height/2.0 ) )
      await setup.setSize(size)
    }
  }

  func draw(in view: MTKView) {
    //    shader.metalView = view

    if isRunningx {

      if isSteppingx {
        isRunningx = false
        isSteppingx = false
      }
      guard doRunning() else { return }
      ddraw( commandQueue, view, nil)
    }
  }

}

class FrameTimer : ObservableObject {
  @Published var shaderPlayerTime : String = ""
  @Published var shaderFPS : String = ""
}

