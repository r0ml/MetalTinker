// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import MetalKit
import os
import AVFoundation
import SwiftUI

class GenericShader : Identifiable {

  /// This is the CPU overlay on the initialization buffer
  var inbuf : MyMTLStruct!

  /// this is the clear color for alpha blending?
  var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )
  var cached : [IdentifiableView]?


  var myOptions : MyMTLStruct!
  var dynPref : DynamicPreferences? // need to hold on to this for the callback


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
  
  required init(_ s : String ) {
    //    print("ShaderFilter init \(s)")
    myName = s
    //    print("init \(s)")
    self.doInitialization()
  }


  var function = Function("Generators")


  func finishCommandEncoding(_ renderEncoder : MTLRenderCommandEncoder, _ config : GenericShader) {

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

    let vertexProgram = currentVertexFn()
    let fragmentProgram = currentFragmentFn()

    if let rpp = setupRenderPipeline(vertexFunction: vertexProgram, fragmentFunction: fragmentProgram) {
      (self.pipelineState, _) = rpp
    }

    justInitialization()

    self.specialInitialization()

    frameInitialize()

  }


  func frameInitialize() {
    // await super.justInitialization()
    let nam = myName + "FrameInitialize"
    guard let initializationProgram = functionMaps["Generators"]!.find( nam ) else {
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
    let nam = myName + "InitializeOptions"
    guard let initializationProgram = functionMaps["Generators"]!.find( nam ) else {
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


  func currentVertexFn() -> MTLFunction? {
    let lun = "\(myName)______Vertex"
    if let z = functionMaps["Generators"]!.find(lun) { return z }
    return functionMaps["Generators"]!.find("flatVertexFn")!
  }


  func currentFragmentFn() -> MTLFunction? {
    let lun = "\(myName)______Fragment"
    if let z = functionMaps["Generators"]!.find(lun) { return z }
    return functionMaps["Generators"]!.find("passthruFragmentFn")!
  }


  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering
  func doRenderEncoder(
    _ xview : MTKView,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
//    _ rpd : MTLRenderPassDescriptor,
    delegate : MetalDelegate,
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


// At this point:
      // If I am doing a multi-pass, then I must:
      // 1) create the render textures for the multiple passes
      // 2) create multiple render passes
      // 3) blit the outputs to inputs for the next frame (or swap the inputs and outputs

      makeEncoder(commandBuffer, scale, xview.currentRenderPassDescriptor!, delegate: delegate)

      if let c = xview.currentDrawable {

        let kk = xview.currentRenderPassDescriptor!

        //      let rt = self.renderPassDescriptor(delegate.mySize!).colorAttachments[0].resolveTexture //  frpp.resolveTextures.1

        // =========================================================================
        // if feeding back output from previous frame to next frame:

        // ========================================================================

        // what I want here is the resolve texture of the last pipeline pass
        commandBuffer.addCompletedHandler{ commandBuffer in
          if let f = f {
            // print("resolved texture")
            //         f( rpd.colorAttachments[0].resolveTexture  )
            f(c.texture)
          }
        }
        commandBuffer.present(c)
      }
      commandBuffer.commit()
      //      commandBuffer.waitUntilCompleted()
    }



/// =====================================================================================================================

  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                           _ scale : CGFloat,
                           _ rpd : MTLRenderPassDescriptor,
                           delegate : MetalDelegate) {

    // to get the running shader to match the preview?
    // FIXME: do I have clearColor?
    //    if let cc = rm.metalView?.clearColor {
    //      rpd.colorAttachments[0].clearColor = cc


    // FIXME: should this be a clear or load?
    rpd.colorAttachments[0].loadAction = .clear // .load
    rpd.colorAttachments[0].storeAction = .multisampleResolve
    //    }

    let sz = CGSize(width : rpd.colorAttachments[0].texture!.width, height: rpd.colorAttachments[0].texture!.height )
    delegate.setup.setupUniform( size: sz, scale: Int(scale), uniform: delegate.shader.uniformBuffer!, times: delegate.times )

    // texture and resolveTexture size mismatch    during resize
    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder"

      let config = delegate.shader
      renderEncoder.setFragmentBuffer(config.uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setFragmentBuffer(config.initializationBuffer, offset: 0, index: kbuffId)
      self.finishCommandEncoding(renderEncoder, config)

      renderEncoder.endEncoding()
    }
  }


// =============================================================================================================================================

  // this draws the current frame
  func draw(in viewx: MTKView, delegate : MetalDelegate) {
    // FIXME: set the clear color
    //      viewx.clearColor = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))

    // FIXME: abort the whole execution if ....
    // if I get an error "Execution of then command buffer was aborted due to an error during execution"
    // in here, any calculations based on difference between this time and last time?
//    if let rpd = viewx.currentRenderPassDescriptor {

      // to get the running shader to match the preview?
      // rpd.colorAttachments[0].clearColor = viewx.clearColor

      self.doRenderEncoder(viewx, delegate : delegate ) { _ in
        // FIXME: this is the thing that will record the video frame
        // self.videoRecorder?.writeFrame(forTexture: viewx.currentDrawable!.texture)
        delegate.gpuSemaphore.signal()
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
//      let c = ImageStrip(texes: Binding.init(get: { return self.fragmentTextures } , set: { self.fragmentTextures = $0 }))
      let k = /* [IdentifiableView(id: "sources", view: AnyView(c))] + */ a.buildOptionsPane(mo)
      cached = k
      return k
    }
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


      // at this point, the initialization (preferences) buffer has been set
      if let gg = initializeReflection?.arguments.first(where: { $0.name == "in" }) {
        inbuf = MyMTLStruct.init(initializationBuffer, gg)
        processArguments(inbuf)
      }

      getClearColor(inbuf)
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
