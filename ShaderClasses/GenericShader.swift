// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import MetalKit
import os
import AVFoundation
import SwiftUI
import SceneKit

class GenericShader : NSObject, Identifiable, ObservableObject {
  @Published var isRunning : Bool = false
  var isStepping : Bool = false
  
  var metadata : MTLRenderPipelineReflection!


  
  /// This is the CPU overlay on the initialization buffer
  var inbuf : MyMTLStruct!
  
  /// this is the clear color for alpha blending?
  var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )
  var cached : [IdentifiableView]?
  
  
  var myOptions : MyMTLStruct!
  var dynPref : DynamicPreferences? // need to hold on to this for the callback
  
  var myGroup : String {
    get { "Generators" }
  }
  
  public var id : String {
    return myName
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
  
  var initializeReflection : MTLComputePipelineReflection?
  var initializePipelineState : MTLComputePipelineState?
  
  // Config Controller
  /// This buffer is known as in on the metal side
  var initializationBuffer : MTLBuffer!
  var uniformBuffer : MTLBuffer?
  
  var pipelineState : MTLRenderPipelineState!
  
  // from Delegate
  var videoRecorder : MetalVideoRecorder?
  var times = Times()
  var frameTimer = FrameTimer()
  var fpsSamples : [Double] = Array(repeating: 1.0/60.0 , count: 60)
  var fpsX : Int = 0
  
  //  var uniformBuffer : MTLBuffer!
  var setup = RenderSetup()
  var mySize : CGSize?
  
  var textureSize : CGSize?
  var renderPassDescriptor : MTLRenderPassDescriptor?
  
  let semCount = 1
  var gpuSemaphore : DispatchSemaphore = DispatchSemaphore(value: 1)
  
  
  
  
  
  
  
  required init(_ s : String ) {
    //    print("ShaderFilter init \(s)")
    
    myName = s
    super.init()
    //    print("init \(s)")
    self.doInitialization()
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
      (self.pipelineState, self.metadata) = rpp
    }
    
    justInitialization()
    
    self.specialInitialization()
    
    frameInitialize()
    
  }
  
  
  func frameInitialize() {
    // await super.justInitialization()
    let nam = myName + "FrameInitialize"
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
  
  func justInitialization() {
    // await super.justInitialization()
    
    var ibl = 8
    if let aa = (self.metadata.fragmentArguments?.filter { $0.name == "in" })?.first {
      ibl = aa.bufferDataSize
    } else if let bb = (self.metadata.vertexArguments?.filter { $0.name == "in" })?.first {
      ibl = bb.bufferDataSize
    }
    if ibl == 0 { ibl = 8 }
    
    if let ib = device.makeBuffer(length: ibl, options: [.storageModeShared ]) {
      ib.label = "defaults buffer for \(self.myName)"
      ib.contents().storeBytes(of: 0, as: Int.self)
      self.initializationBuffer = ib
    }
    
    let nam = myName + "InitializeOptions"
    guard let initializationProgram = functionMaps[self.myGroup]!.find( nam ) else {
      return
    }
    let cpld = MTLComputePipelineDescriptor()
    cpld.computeFunction = initializationProgram
    
    
  
    do {
      initializePipelineState = try device.makeComputePipelineState(function: initializationProgram,
                                                                    options:[.argumentInfo, .bufferTypeInfo], reflection: &initializeReflection)
    } catch {
      os_log("%s", type:.fault, "failed to initialize pipeline state for \(myName): \(error)")
      return
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
    _ cq : MTLCommandQueue?,
    _ xview : MTKView?,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    _ scene : SCNScene?,
    //    _ rpd : MTLRenderPassDescriptor,
    //    delegate : MetalDelegate,
    _ f : ((MTLTexture?) -> ())? ) { // for off-screen renderings, use a callback function instead of a semaphore?
      
      doRenderEncoder1(xview)
      if let xvv = xview {
        doRenderEncoder3(xvv, f)
      } else {
        doRenderEncoder2(cq, scene, f)
      }
    }
  
  
  func doRenderEncoder1(_ xview : MTKView?) {
    // FIXME: what is this in iOS land?  What is it in mac land?
    
    var scale : Int = 1
#if os(macOS)
    if let xvv = xview {
     let eml = NSEvent.mouseLocation
     let wp = xvv.window!.convertPoint(fromScreen: eml)
     let ml = xvv.convert(wp, from: nil)
     
     if xvv.isMousePoint(ml, in: xvv.bounds) {
     setup.mouseLoc = ml
     }
     scale = Int(xvv.window?.screen?.backingScaleFactor ?? 1)
    }
#endif
    
#if targetEnvironment(macCatalyst)
    if let xvv = xview {
    let ourEvent = CGEvent(source: nil)!
    let point = ourEvent.unflippedLocation
      let xscale =  xvv.window!.screen?.backingScaleFactor // was scale
    //      let ptx = CGPoint(x: point.x / xscale, y: point.y / xscale)
    //
    
    
    let offs = (NSClassFromString("NSApplication")?.value(forKeyPath: "sharedApplication.windows._frame") as? [CGRect])![0]
    
    //      let offs = ws.value(forKeyPath: "_frame") as! CGRect
    //      let soff = ws.value(forKeyPath: "screen._frame") as! CGRect
    
    let loff = xvv.convert(CGPoint.zero, to: xvv.window!)
    let ptx = CGPoint(x: point.x - offs.minX, y: point.y - offs.minY )
    let lpoint = CGPoint(x: ptx.x - loff.x, y: ptx.y - loff.y)
    
    scale = xscale
    
    // I don't know why the 40 is needed -- but it seems to work
    let zlpoint = CGPoint(x: lpoint.x, y: lpoint.y - xvv.bounds.height - 40 )
    if zlpoint.x >= 0 && zlpoint.y >= 0 && zlpoint.x < xvv.bounds.width && zlpoint.y < xvv.bounds.height {
      delegate.setup.mouseLoc = zlpoint
    }
    }
#endif
  }
  
  func doRenderEncoder2( _ cq : MTLCommandQueue?,  _ scene: SCNScene?, _ f : ((MTLTexture?) -> ())? )  {

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
    let msiz = mySize ?? CGSize(width: 100, height: 100)
    let rpd = makeRenderPassDescriptor(label: "appRenderPass", scale: multisampleCount, size: msiz, scene)
    // the rpd color attachments should have the right textures in them
    makeEncoder(commandBuffer, multisampleCount, rpd)
    
    //    if let c = xview.currentDrawable {
    
    //      let kk = xview.currentRenderPassDescriptor!
    
    //      let rt = self.renderPassDescriptor(delegate.mySize!).colorAttachments[0].resolveTexture //  frpp.resolveTextures.1
    
    // =========================================================================
    // if feeding back output from previous frame to next frame:
    
    // ========================================================================
    
    doRenderEncoder4(commandBuffer, msiz, rpd)
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
  
  func doRenderEncoder4(_ commandBuffer : MTLCommandBuffer, _ size : CGSize, _ kk : MTLRenderPassDescriptor) {
    
  }
  
  func doRenderEncoder3( _ xvv: MTKView, _ f : ((MTLTexture?) -> ())? )  {

    // Set up the command buffer for this frame

    let cqq = commandQueue
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
    makeEncoder(commandBuffer, multisampleCount, rpd)
    
    if let c = xvv.currentDrawable {
    
      let kk = xvv.currentRenderPassDescriptor!
    
    //      let rt = self.renderPassDescriptor(delegate.mySize!).colorAttachments[0].resolveTexture //  frpp.resolveTextures.1
    
      let msiz = CGSize(width: c.texture.width, height: c.texture.height)
      doRenderEncoder4(commandBuffer, msiz, kk )
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
      let (texture, resolveTexture) = makeRenderPassTexture(label, scale: scale, size: canvasSize)!
      scene?.background.contents = nil
      scene?.background.contents = resolveTexture
      
      let renderPassDescriptor = MTLRenderPassDescriptor()
      renderPassDescriptor.colorAttachments[0].texture = texture
      renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
      renderPassDescriptor.colorAttachments[0].resolveLevel = 0
      renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTexture //  device.makeTexture(descriptor: xostd)
      renderPassDescriptor.colorAttachments[0].loadAction = .clear // .clear // .load
      //      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)
      self.renderPassDescriptor = renderPassDescriptor
    }
    
    // only if I need depthing?
    // renderPassDescriptor.depthAttachment = RenderPipelinePass.makeDepthAttachmentDescriptor(size: canvasSize)
    
    return renderPassDescriptor!
  }
  
  
  func makeRenderPassTexture(_ nam : String, scale: Int, size: CGSize) -> (MTLTexture, MTLTexture)? {
    let texd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
    texd.textureType = .type2DMultisample
    texd.usage = [.renderTarget]
    texd.sampleCount = scale
    texd.resourceOptions = .storageModePrivate
    
    /*
     let texi = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */ , width: Int(size.width), height: Int(size.height), mipmapped: true)
     texi.textureType = .type2D
     texi.usage = [.shaderRead]
     texi.resourceOptions = .storageModePrivate
     */
    let texo = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
    texo.textureType = .type2D
    texo.usage = [.renderTarget, .shaderWrite, .shaderRead] // or just renderTarget -- the read is in case the texture is used in a filter
    texo.resourceOptions = .storageModePrivate
    
    
    let texl = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
    texl.textureType = .type2D
    texl.usage = [.shaderRead] // or just renderTarget -- the read is in case the texture is used in a filter
    texl.resourceOptions = .storageModePrivate
    
    
    if let p = device.makeTexture(descriptor: texd),
       //       let q = device.makeTexture(descriptor: texi),
       let r = device.makeTexture(descriptor: texo),
       let s = device.makeTexture(descriptor: texl) {
      p.label = "render pass \(nam) multisample"
      //      q.label = "render pass \(nam) input"
      r.label = "render pass \(nam) output"
      s.label = "render pass \(nam) last frame"
      //        swapQ.async {
      
      /*     for k in fragmentTextures {
       if k.name == "lastFrame" {
       k.texture = s
       }
       }
       */
      return (p, r)
    }
    return nil
  }
  
  
  
  
  
  
  /// =====================================================================================================================
  
  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : Int,
                   _ rpd : MTLRenderPassDescriptor
                   //                           delegate : MetalDelegate
  ) {
    
    // to get the running shader to match the preview?
    // FIXME: do I have clearColor?
    //    if let cc = rm.metalView?.clearColor {
    //      rpd.colorAttachments[0].clearColor = cc
    
    
    
    // FIXME: should this be a clear or load?
    rpd.colorAttachments[0].loadAction = .clear // .load
    rpd.colorAttachments[0].storeAction = .multisampleResolve
    //    }
    
    let sz = CGSize(width : rpd.colorAttachments[0].texture!.width, height: rpd.colorAttachments[0].texture!.height )
    setup.setupUniform( size: sz, scale: scale, uniform: uniformBuffer!, times: times )
    
    // texture and resolveTexture size mismatch    during resize
    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder"
      
      renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setFragmentBuffer(initializationBuffer, offset: 0, index: kbuffId)
      self.finishCommandEncoding(renderEncoder)
      
      renderEncoder.endEncoding()
    }
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
    
    self.doRenderEncoder( cq, viewx, scene)
        { _ in
      // FIXME: this is the thing that will record the video frame
      // self.videoRecorder?.writeFrame(forTexture: viewx.currentDrawable!.texture)
      self.gpuSemaphore.signal()
    }
    
    //  }
  }
  
  
  // =============================================================================================================================================
  
  // this is getting called during onTapGesture in LibraryView -- when I'm launching the ShaderView
  func buildPrefView() -> [IdentifiableView] {
    beginShader()
    if let z = cached { return z }
    if let mo = myOptions {
      let a = DynamicPreferences.init(myName)
      dynPref = a
      
      
      let jj = self.morePrefs()
      //      let c = ImageStrip(texes: Binding.init(get: { return self.fragmentTextures } , set: { self.fragmentTextures = $0 }))
      let k = jj + /* [IdentifiableView(id: "sources", view: AnyView(c))] + */ a.buildOptionsPane(mo)
      cached = k
      return k
    }
    return []
  }
  
  func morePrefs() -> [IdentifiableView] {
    return []
  }
  
  func beginShader() {
    //    print("start \(#function)")
    
    if let ips = initializePipelineState,
       let commandBuffer = commandQueue.makeCommandBuffer(),
       let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
      commandBuffer.label = "Initialize command buffer for \(self.myName) "
      computeEncoder.label = "initialization and defaults encoder \(self.myName)"
      computeEncoder.setComputePipelineState(ips)
      //        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
      computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)
      
      let ms = MTLSize(width: 1, height: 1, depth: 1);
      computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
      computeEncoder.endEncoding()
      
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed
    }
      
      // at this point, the initialization (preferences) buffer has been set
//      if let gg = initializeReflection?.arguments.first(where: { $0.name == "in" }) {
    if let gg = metadata.fragmentArguments?.first(where: {$0.name == "in" } ) {
        inbuf = MyMTLStruct.init(initializationBuffer, gg)
        processArguments(inbuf)
      
      getClearColor(inbuf)
    }
  }
  
  func beginFrame(_ cqq : MTLCommandQueue) {
    //        print("start \(#function)")
    
    /*      // FIXME: I want the render pipeline metadata
     
     if let gg = cpr?.arguments.first(where: { $0.name == "in" }),
     let ib = device.makeBuffer(length: gg.bufferDataSize, options: [.storageModeShared ]) {
     ib.label = "defaults buffer for \(self.myName)"
     ib.contents().storeBytes(of: 0, as: Int.self)
     initializationBuffer = ib
     } else if let ib = device.makeBuffer(length: 8, options: [.storageModeShared]) {
     ib.label = "empty kernel compute buffer for \(self.myName)"
     initializationBuffer = ib
     } else {
     os_log("failed to allocate initialization MTLBuffer", type: .fault)
     return
     }
     */
    
    
    if
       let fips = frameInitializePipelineState,
       let commandBuffer = cqq.makeCommandBuffer(),
       let computeEncoder = commandBuffer.makeComputeCommandEncoder()
    {
      commandBuffer.label = "Frame Initialize command buffer for \(self.myName)"
      computeEncoder.label = "frame initialization and defaults encoder \(self.myName)"
      computeEncoder.setComputePipelineState(fips)
      //        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
      computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)
      
      let ms = MTLSize(width: 1, height: 1, depth: 1);
      computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
      computeEncoder.endEncoding()
      
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed
    }
    
    // at this point, the frame initialization (ctrl) buffer has been set
    // FIXME: I should probably add a compute buffer to hold values across frames?
    
    /*    if let gg = cpr?.arguments.first(where: { $0.name == "in" }) {
     inbuf = MyMTLStruct.init(initializationBuffer, gg)
     processArguments(inbuf)
     }
     */
    
    
  }
  
  
  func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?) -> (MTLRenderPipelineState, MTLRenderPipelineReflection)? {
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
          return (res, m)
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
  
  
  func processArguments(_ bst : MyMTLStruct ) {
    
    myOptions = bst
    
    for bstm in myOptions.children {
      let dnam = "\(self.myName).\(bstm.name!)"
      // if this key already has a value, ignore the initialization value
      let dd =  UserDefaults.standard.object(forKey: dnam)
      
      if let _ = bstm.structure {
        let ddm = bstm.children
        if let kk = bstm.children.first?.datatype, kk == .int {
          self.segmented(bstm.name, ddm)
        }
        // self.dropDown(bstm.name, ddm) } }
        
      } else {
        
        let dat = bstm.value
        switch dat {
        case is Bool:
          let v = dat as! Bool
          UserDefaults.standard.set(dd ?? v, forKey: dnam)
          self.boolean(bstm);
          
        case is SIMD4<Float>:
          let v = dat as! SIMD4<Float>
          UserDefaults.standard.set(dd ?? v.y, forKey: dnam)
          self.colorPicker( bstm)
          
        case is SIMD3<Float>:
          let v = dat as! SIMD3<Float>
          UserDefaults.standard.set(dd ?? v.y, forKey: dnam)
          self.numberSliderFloat( bstm )
          
        case is SIMD3<Int32>:
          let v = dat as! SIMD3<Int32>
          UserDefaults.standard.set(dd ?? v.y, forKey: dnam)
          self.numberSliderInt( bstm )
          
        default:
          os_log("%s", type:.error, "\(bstm.name!) is \(bstm.datatype)")
        }
      }
    }
  }
  
  
  
  func segmented( _ t:String, _ items : [MyMTLStruct]) {
    let iv = UserDefaults.standard.integer(forKey: "\(self.myName).\(t)")
    setPickS(iv, items)
  }
  
  // FIXME: this is a duplicate of the one in DynamicPreferences
  func setPickS(_ a : Int, _ items : [MyMTLStruct] ) {
    for (i, tt) in items.enumerated() {
      tt.setValue(i == a ? 1 : 0 )
    }
  }
  
  func boolean(_ arg : MyMTLStruct) {
    arg.setValue( UserDefaults.standard.bool(forKey: "\(self.myName).\(arg.name!)") )
  }
  
  func colorPicker(_ arg : MyMTLStruct) {
    if let iv = UserDefaults.standard.color(forKey: "\(self.myName).\(arg.name!)") {
      arg.setValue(iv.asFloat4())
    }
  }
  
  func numberSliderInt(_ arg : MyMTLStruct) {
    let iv = UserDefaults.standard.integer(forKey: "\(self.myName).\(arg.name!)")
    // note the ".y"
    if var z : SIMD3<Int32> = arg.value as? SIMD3<Int32> {
      z.y = Int32(iv)
      arg.setValue(z)
    }
  }
  
  func numberSliderFloat(_ arg : MyMTLStruct) {
    let iv = UserDefaults.standard.float(forKey: "\(self.myName).\(arg.name!)")
    // note the ".y"
    if var z : SIMD3<Float> = arg.value as? SIMD3<Float> {
      z.y = iv
      arg.setValue(z)
    }
  }
  
  
  
  // FIXME: do I need this?
  func getClearColor(_ bst : MyMTLStruct) {
    guard let bb = bst["clearColor"] else { return }
    let v : SIMD4<Float> = bb.getValue()
    self.clearColor = v
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
      setup.iFrame -= 2;
    } else {
      paused -= (1/60.0)
    }
    times.startTime += paused
    times.lastTime += paused
    
    isRunning = true
    isStepping = true
    //    self.draw(in: metalView!)
  }
  
  func play() {
    times.currentTime = now()
    let paused = times.currentTime - times.lastTime
    times.startTime += paused
    times.lastTime += paused
    
    //   shader.config.videoNames.forEach { $0.start() }
    
    isRunning = true
    isStepping = false
    
    startRunning()
  }
  
  func stop() {
    isRunning = false
    isStepping = true
    stopRunning()
    
    // config.webcam?.stopCapture()
    // config.videoNames.forEach { $0.pause() }
    
    NotificationCenter.default.removeObserver(self)
  }
  
  func rewind(_ sender : Any? = nil) {
    let n = now()
    times.lastTime = n
    times.currentTime = n
    times.startTime = n
    setup.iFrame = -1
  }
  
  
  func doRunning( /* _ view : MTKView */ ) {
    
    // FIXME: sometimes I get trapped here!
    //      print("in gpusem", terminator: "" )
    let gw = gpuSemaphore.wait(timeout: .now() + .microseconds(1) /*    .microseconds(1000/60) */ )
    if gw == .timedOut { return }
    
    times.lastTime = times.currentTime
    times.currentTime = now()
    
    // calculate and display the Frames Per Second

    // FIXME: put me back
    // just this doubles the CPU requirement.
    // can I make the frameTimer update be more efficient?
    
    
    fpsSamples[fpsX] = times.currentTime - times.lastTime
    fpsX += 1
    if fpsX == fpsSamples.count { fpsX = 0 }

    if 0 == setup.iFrame % 60 {

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
  }
}


extension GenericShader : MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    setup.mouseLoc = CGPoint(x: size.width / 2.0, y: size.height/2.0 )
    mySize = size;
  }
  
  func draw(in view: MTKView) {
    //    shader.metalView = view
    
    if isRunning {
      
      if isStepping {
        isRunning = false
        isStepping = false
      }
      doRunning()
      ddraw( commandQueue, view, nil)
    }
  }
  
}

class FrameTimer : ObservableObject {
  @Published var shaderPlayerTime : String = ""
  @Published var shaderFPS : String = ""
}

