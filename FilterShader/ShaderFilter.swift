
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os
import SwiftUI

#if targetEnvironment(macCatalyst)
import UIKit
#endif

/* TODO:
 1) There is a flicker when resuming after pause (on macCatalyst).  The first frame after pause seems to (someetimes) be frame 0 -- not the current frame
 2) Can I update the thumbnail as the video plays?
 3) Single step is not working
 4) recording and snapshotting is not working
 5) instead of using a separate initialization function in the shader, I could use the fragment function (which also has the "in" parameter) and have the shader macro call initialize() on frame 0
 6) Camera sometimes doesn't shut off when moving to different shader.
 7) Need to set the zoom explicitly (it stays set to previous user -- so Librorum altered it -- for MacOS only it seems
 8) aspect ratio seems off for MacOS on second camera
 9) Switching cameras doesn't turn off the one being switched away from (macOS)
 10) Snapshot icon doesn't show up for MacCatalyst
 */

let ctrlBuffId = 4

final class ShaderFilter : Shader {

  static var function = Function("Filters")
  var myName : String

  private var frameInitializeReflection : MTLComputePipelineReflection?
  private var frameInitializePipelineState : MTLComputePipelineState?

  private var initializeReflection : MTLComputePipelineReflection?
  private var initializePipelineState : MTLComputePipelineState?

  // Config Controller
  /// This buffer is known as in on the metal side
  private var initializationBuffer : MTLBuffer!
  /// This is the CPU overlay on the initialization buffer
  private var inbuf : MyMTLStruct!

  /// this is the clear color for alpha blending?
  private var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )
  private var cached : [IdentifiableView]?

  private var fragmentTextures : [TextureParameter] = []

  private var myOptions : MyMTLStruct!
  private var dynPref : DynamicPreferences? // need to hold on to this for the callback
  private var computeBuffer : MTLBuffer?

  private var uniformBuffer : MTLBuffer?
  private var controlBuffer : MTLBuffer!

  private var _renderPassDescriptor : MTLRenderPassDescriptor?
  private var _mySize : CGSize?

  private var pipelineState : MTLRenderPipelineState!
  private var metadata : MTLRenderPipelineReflection!
  private var renderInput : [(MTLTexture, MTLTexture, MTLTexture)] = []

  private func doInitialization( ) {
    let uniformSize : Int = MemoryLayout<Uniform>.stride
#if os(macOS) || targetEnvironment(macCatalyst)
    let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
#else
    let uni = device.makeBuffer(length: uniformSize, options: [])!
#endif

    controlBuffer = device.makeBuffer(length: MemoryLayout<ControlBuffer>.stride, options: [.storageModeShared] )!
    let c = controlBuffer.contents().assumingMemoryBound(to: ControlBuffer.self)
    c.pointee.topology = 3
    c.pointee.vertexCount = 4
    c.pointee.instanceCount = 1

    uni.label = "uniform"
    uniformBuffer = uni
    fragmentTextures = []

    let vertexProgram = currentVertexFn()
    let fragmentProgram = currentFragmentFn()

    if let rpp = setupRenderPipeline(vertexFunction: vertexProgram, fragmentFunction: fragmentProgram) {
      (self.pipelineState, self.metadata) = rpp
    }

    justInitialization()

    let aa = metadata
    let bb = aa?.fragmentArguments

    if let a = bb {
      processTextures(a)
    }

    frameInitialize()

  }

  func setupFrame(_ t : Times) {
    for (i,v) in fragmentTextures.enumerated() {
      if let vs = v.video {
        fragmentTextures[i].texture = vs.readBuffer(t.currentTime) //     v.prepare(stat, currentTime - startTime)
      }
    }
  }

  required init(_ s : String ) {
    //    print("ShaderFilter init \(s)")
    myName = s
    //    print("init \(s)")
    self.doInitialization()
  }

  private func frameInitialize() {
    // await super.justInitialization()
    let nam = myName + "FrameInitialize"
    guard let initializationProgram = Self.function.find( nam ) else {
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


  func beginFrame() {
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


    if let commandBuffer = commandQueue.makeCommandBuffer(),
       let fips = frameInitializePipelineState,
       let computeEncoder = commandBuffer.makeComputeCommandEncoder()
    {
      commandBuffer.label = "Frame Initialize command buffer for \(self.myName)"
      computeEncoder.label = "frame initialization and defaults encoder \(self.myName)"
      computeEncoder.setComputePipelineState(fips)
      //        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
      computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)
      computeEncoder.setBuffer(controlBuffer, offset: 0, index: ctrlBuffId)

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



  private func justInitialization() {
    // await super.justInitialization()
    let nam = myName + "InitializeOptions"
    guard let initializationProgram = Self.function.find( nam ) else {
//      print("no initialization program for \(self.myName)")
      if let ib = device.makeBuffer(length: 8, options: [.storageModeShared]) {
        ib.label = "empty kernel compute buffer for \(self.myName)"
        initializationBuffer = ib
      }
      return
    }
    let cpld = MTLComputePipelineDescriptor()
    cpld.computeFunction = initializationProgram

    do {
      initializePipelineState = try device.makeComputePipelineState(function: initializationProgram,
                                                                    options:[.argumentInfo, .bufferTypeInfo], reflection: &initializeReflection)
      if let gg = initializeReflection?.arguments.first(where: { $0.name == "in" }),
         let ib = device.makeBuffer(length: gg.bufferDataSize, options: [.storageModeShared ]) {
        ib.label = "defaults buffer for \(self.myName)"
        ib.contents().storeBytes(of: 0, as: Int.self)
        initializationBuffer = ib
      } else {
        os_log("failed to allocate initialization MTLBuffer", type: .fault)
        return
      }
    } catch {
      os_log("%s", type:.fault, "failed to initialize pipeline state for \(myName): \(error)")
      return
    }
  }

  private func beginShader() {
    //    print("start \(#function)")

    if let ips = initializePipelineState,
       let commandBuffer = commandQueue.makeCommandBuffer(),
       let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
      commandBuffer.label = "Initialize command buffer for \(self.myName) "
      computeEncoder.label = "initialization and defaults encoder \(self.myName)"
      computeEncoder.setComputePipelineState(ips)
      //        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
      computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)
      computeEncoder.setBuffer(controlBuffer, offset: 0, index: ctrlBuffId)

      let ms = MTLSize(width: 1, height: 1, depth: 1);
      computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
      computeEncoder.endEncoding()

      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed


      // at this point, the initialization (preferences) buffer has been set
      if let gg = initializeReflection?.arguments.first(where: { $0.name == "in" }) {
        inbuf = MyMTLStruct.init(initializationBuffer, gg)
        processArguments(inbuf)
      }

      getClearColor(inbuf)
    }
  }

  private func currentVertexFn() -> MTLFunction? {
    let lun = "\(myName)______Vertex"
    if let z = Self.function.find(lun) { return z }
    return Self.function.find("flatVertexFn")!
  }


  private func currentFragmentFn() -> MTLFunction? {
    let lun = "\(myName)______Fragment"
    if let z = Self.function.find(lun) { return z }
    return Self.function.find("passthruFragmentFn")!
  }


  // this is getting called during onTapGesture in LibraryView -- when I'm launching the ShaderView
  func buildPrefView() -> [IdentifiableView] {
    beginShader()
    if let z = cached { return z }
    if let mo = myOptions {
      let a = DynamicPreferences.init(myName)
      dynPref = a
      let c = ImageStrip(texes: Binding.init(get: { return self.fragmentTextures } , set: { self.fragmentTextures = $0 }))
      let k = [IdentifiableView(id: "sources", view: AnyView(c))] + a.buildOptionsPane(mo)
      cached = k
      return k
    }
    return []
  }

  // FIXME: do I need this?
  func getClearColor(_ bst : MyMTLStruct) {
    guard let bb = bst["clearColor"] else { return }
    let v : SIMD4<Float> = bb.getValue()
    self.clearColor = v
  }


  // let's assume this is where the shader starts running, so shader initialization should happen here.
  func startRunning() {
    for v in fragmentTextures {
      if let vs = v.video {
        vs.startVideo()
      }
    }
  }

  func stopRunning() {
    for v in fragmentTextures {
      if let vs = v.video {
        vs.stopVideo()
      }
    }
  }


  // this draws the current frame
  func draw(in viewx: MTKView, delegate : MetalDelegate<ShaderFilter>) {
    // FIXME: set the clear color
    //      viewx.clearColor = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))

    // FIXME: abort the whole execution if ....
    // if I get an error "Execution of then command buffer was aborted due to an error during execution"
    // in here, any calculations based on difference between this time and last time?
    if let rpd = viewx.currentRenderPassDescriptor {

      // to get the running shader to match the preview?
      // rpd.colorAttachments[0].clearColor = viewx.clearColor

      self.doRenderEncoder(viewx, rpd, delegate : delegate ) { _ in
        // FIXME: this is the thing that will record the video frame
        // self.videoRecorder?.writeFrame(forTexture: viewx.currentDrawable!.texture)
        delegate.gpuSemaphore.signal()
      }
    }
  }

  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering
  private func doRenderEncoder(
    _ xview : MTKView,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    _ rpd : MTLRenderPassDescriptor,
    delegate : MetalDelegate<ShaderFilter>,
    _ f : ((MTLTexture?) -> ())? ) { // for off-screen renderings, use a callback function instead of a semaphore?


      // FIXME: what is this in iOS land?  What is it in mac land?

      var scale : CGFloat = 1
#if os(macOS)
      let eml = NSEvent.mouseLocation
      let wp = xview.window!.convertPoint(fromScreen: eml)
      let ml = xview.convert(wp, from: nil)

      if xview.isMousePoint(ml, in: xview.bounds) {
        delegate.setup.mouseLoc = ml
      }

      scale = xview.window?.screen?.backingScaleFactor ?? 1
#endif

#if targetEnvironment(macCatalyst)

      let ourEvent = CGEvent(source: nil)!
      let point = ourEvent.unflippedLocation
      let xscale =  xview.window!.screen.scale
      //      let ptx = CGPoint(x: point.x / xscale, y: point.y / xscale)
      //


      let offs = (NSClassFromString("NSApplication")?.value(forKeyPath: "sharedApplication.windows._frame") as? [CGRect])![0]

      //      let offs = ws.value(forKeyPath: "_frame") as! CGRect
      //      let soff = ws.value(forKeyPath: "screen._frame") as! CGRect

      let loff = xview.convert(CGPoint.zero, to: xview.window!)
      let ptx = CGPoint(x: point.x - offs.minX, y: point.y - offs.minY )
      let lpoint = CGPoint(x: ptx.x - loff.x, y: ptx.y - loff.y)

      scale = xscale

      // I don't know why the 40 is needed -- but it seems to work
      let zlpoint = CGPoint(x: lpoint.x, y: lpoint.y - xview.bounds.height - 40 )
      if zlpoint.x >= 0 && zlpoint.y >= 0 && zlpoint.x < xview.bounds.width && zlpoint.y < xview.bounds.height {
        delegate.setup.mouseLoc = zlpoint
      }
#endif

      beginFrame()

      // Set up the command buffer for this frame
      let commandBuffer = commandQueue.makeCommandBuffer()!
      commandBuffer.label = "Render command buffer for \(self.myName)"

      makeEncoder(commandBuffer, scale, rpd, delegate: delegate)

      // =========================================================================

      let rt = self.renderPassDescriptor(delegate.mySize!).colorAttachments[0].resolveTexture //  frpp.resolveTextures.1

      // what I want here is the resolve texture of the last pipeline pass
      commandBuffer.addCompletedHandler{ commandBuffer in
        if let f = f {
          // print("resolved texture")
          //         f( rpd.colorAttachments[0].resolveTexture  )
          f(rt)
        }
      }

      if let c = xview.currentDrawable {
        commandBuffer.present(c)
      }
      commandBuffer.commit()
    }

  
  private func renderPassDescriptor(_ mySize : CGSize) -> MTLRenderPassDescriptor {
    if let rr = _renderPassDescriptor,
       mySize == _mySize {
      return rr }
    let k = makeRenderPassDescriptor(label: "render output", size: mySize)
    _renderPassDescriptor = k
    _mySize = mySize
    return k
  }
  

  private func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                           _ scale : CGFloat,
                           _ rpd : MTLRenderPassDescriptor,
                           delegate : MetalDelegate<ShaderFilter>) {

    // to get the running shader to match the preview?
    // FIXME: do I have clearColor?
    //    if let cc = rm.metalView?.clearColor {
    //      rpd.colorAttachments[0].clearColor = cc
    //      rpd.colorAttachments[0].loadAction = .clear
    //    }

    let sz = CGSize(width : rpd.colorAttachments[0].texture!.width, height: rpd.colorAttachments[0].texture!.height )
    delegate.setup.setupUniform( size: sz, scale: Int(scale), uniform: delegate.shader.uniformBuffer!, times: delegate.times )

    // texture and resolveTexture size mismatch    during resize
    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder"

      let config = delegate.shader
      renderEncoder.setFragmentBuffer(config.uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setFragmentBuffer(config.initializationBuffer, offset: 0, index: kbuffId)
      for i in 0..<config.fragmentTextures.count {
        if config.fragmentTextures[i].texture == nil {
          config.fragmentTextures[i].texture = config.fragmentTextures[i].image.getTexture(textureLoader, mipmaps: true)
        }
        renderEncoder.setFragmentTexture( config.fragmentTextures[i].texture, index: config.fragmentTextures[i].index)
      }

      // added this for Vertex functions
      renderEncoder.setVertexBuffer(config.uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setVertexBuffer(config.initializationBuffer, offset: 0, index: kbuffId)
      renderEncoder.setVertexBuffer(config.controlBuffer, offset: 0, index: ctrlBuffId)
      // end of vertex add

      renderEncoder.setRenderPipelineState(pipelineState)

      let c = controlBuffer.contents().assumingMemoryBound(to: ControlBuffer.self)


      // A filter render encoder takes a single instance of a rectangle (4 vertices) which covers the input.
      let t = Int(c.pointee.topology)
      if t >= 0 && t <= 3 {
        let topo : MTLPrimitiveType = [.point, .line, .triangle, .triangleStrip][t]

        renderEncoder.drawPrimitives(type: topo, vertexStart: 0, vertexCount: Int(c.pointee.vertexCount), instanceCount: Int(c.pointee.instanceCount) )
      }
      renderEncoder.endEncoding()
    }
  }

  private func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?) -> (MTLRenderPipelineState, MTLRenderPipelineReflection)? {
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


  /** This sets up the initializer by finding the function in the shader,
   using reflection to analyze the types of the argument
   then setting up the buffer which will be the "preferences" buffer.
   It would be the "Uniform" buffer, but that one is fixed, whereas this one is variable -- so it's
   just easier to make it a separate buffer
   */

  private func buildImageWells() -> some View {

    // I believe this is where the ImageStrip sets the images as texture inputs.
    // It is also where the webcam and video support should be assigned
    ImageStrip(texes: Binding.init(get: { return self.fragmentTextures } , set: {
      self.fragmentTextures = $0 }))
  }

  private func processArguments(_ bst : MyMTLStruct ) {

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

  private func processTextures(_ bst : [MTLArgument] ) {
    for a in bst {
      if let b = TextureParameter(a, id: fragmentTextures.count) {
        fragmentTextures.append(b)
      }
    }
  }

  private func segmented( _ t:String, _ items : [MyMTLStruct]) {
    let iv = UserDefaults.standard.integer(forKey: "\(self.myName).\(t)")
    setPickS(iv, items)
  }

  // FIXME: this is a duplicate of the one in DynamicPreferences
  private func setPickS(_ a : Int, _ items : [MyMTLStruct] ) {
    for (i, tt) in items.enumerated() {
      tt.setValue(i == a ? 1 : 0 )
    }
  }

  private func boolean(_ arg : MyMTLStruct) {
    arg.setValue( UserDefaults.standard.bool(forKey: "\(self.myName).\(arg.name!)") )
  }

  private func colorPicker(_ arg : MyMTLStruct) {
    if let iv = UserDefaults.standard.color(forKey: "\(self.myName).\(arg.name!)") {
      arg.setValue(iv.asFloat4())
    }
  }

  private func numberSliderInt(_ arg : MyMTLStruct) {
    let iv = UserDefaults.standard.integer(forKey: "\(self.myName).\(arg.name!)")
    // note the ".y"
    if var z : SIMD3<Int32> = arg.value as? SIMD3<Int32> {
      z.y = Int32(iv)
      arg.setValue(z)
    }
  }

  private func numberSliderFloat(_ arg : MyMTLStruct) {
    let iv = UserDefaults.standard.float(forKey: "\(self.myName).\(arg.name!)")
    // note the ".y"
    if var z : SIMD3<Float> = arg.value as? SIMD3<Float> {
      z.y = iv
      arg.setValue(z)
    }
  }

}
