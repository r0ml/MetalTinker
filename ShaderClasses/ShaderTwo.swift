
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import SwiftUI
import os
import SceneKit


class ShaderTwo : ParameterizedShader {

  override func doInitialization() {
    let uniformSize : Int = MemoryLayout<Uniform>.stride

#if os(macOS) || targetEnvironment(macCatalyst)
let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
#else
let uni = device.makeBuffer(length: uniformSize, options: [])!
#endif

    uni.label = "uniform"
    uniformBuffer = uni


    // FIXME: I will need Depth for vertex shaders
    /*
    let depthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilDescriptor.depthCompareFunction = .less
    depthStencilDescriptor.isDepthWriteEnabled = true // I would like to set this to false for triangle blending
    self.depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
*/
    
//    Task {
      self.justInitialization()


      setupPipelines()

//      if let a = pipelinePasses[0].metadata.fragmentArguments {
//        processTextures(a)
//      }
      getClearColor(inbuf)
// }
 
  
  }

  var depthStencilState : MTLDepthStencilState?
  
  func renderPassDescriptor(_ mySize : CGSize) -> MTLRenderPassDescriptor {
    if let rr = _renderPassDescriptor,
       mySize == _mySize {
      return rr }
    let k = makeRenderPassDescriptor(label: "render output", scale: 1,size: mySize, nil)
    _renderPassDescriptor = k
    _mySize = mySize
    return k
  }
  
  var _renderPassDescriptor : MTLRenderPassDescriptor?
  var _mySize : CGSize?
  
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
    
  func grabVideo(_ times : Times) {
    for (i,v) in fragmentTextures.enumerated() {
      if let vs = v.video {
        fragmentTextures[i].texture = vs.readBuffer(times.currentTime) //     v.prepare(stat, currentTime - startTime)
      }
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
  override func ddraw(_ cq : MTLCommandQueue?, _ viewx:  MTKView?, _ scene : SCNScene? ) {
        // FIXME: set the clear color
        //      viewx.clearColor = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))
        
        // FIXME: abort the whole execution if ....
        // if I get an error "Execution of then command buffer was aborted due to an error during execution"
        // in here, any calculations based on difference between this time and last time?
        if let _ = viewx?.currentRenderPassDescriptor {
          
          // to get the running shader to match the preview?
          // rpd.colorAttachments[0].clearColor = viewx.clearColor

          Task {
            let kk = await RSetup(setup)
          self.doRenderEncoder(kk, cq, viewx, scene ) { _ in
            // FIXME: this is the thing that will record the video frame
            // self.videoRecorder?.writeFrame(forTexture: viewx.currentDrawable!.texture)
            self.gpuSemaphore.signal()
          }
  //      } else {
          //        self.isRunning = false // if I'm not going to set up the gpuSemaphore signal -- time to admit that I must be bailed
  //        delegate.gpuSemaphore.signal()
  //      }
          }
      }
    }
  
  
  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering


  /*
  override func doRenderEncoder(
    _ kk : RSetup,
    _ cq : MTLCommandQueue?,
    _ xview : MTKView?,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    _ scene : SCNScene?,
    //    delegate : MetalDelegate,
    _ f : ((MTLTexture?) -> ())? ) { // for off-screen renderings, use a callback function instead of a semaphore?
            
      var scale : CGFloat = 1
      
      // FIXME: what is this in iOS land?  What is it in mac land?
#if os(macOS)
      if let viewx = xview {let eml = NSEvent.mouseLocation
        let wp = viewx.window!.convertPoint(fromScreen: eml)
        let ml = viewx.convert(wp, from: nil)
        
        if viewx.isMousePoint(ml, in: viewx.bounds) {
          Task { await setup.setTouch(ml) }
        }
        
        scale = xview?.window?.screen?.backingScaleFactor ?? 1
      }
#endif
      
      // Set up the command buffer for this frame
      let  commandBuffer = commandQueue.makeCommandBuffer()!
      commandBuffer.label = "Render command buffer for \(self.myName)"
      
      // load the current time video frames
      
      // I've accidentally loaded up the textures during setup....
      
      // FIXME: Do I need this?
  /*
      if config.pipelinePasses.isEmpty {
        await config.setupPipelines()
        config.pipelinePasses.forEach { if let z = $0 as? RenderPipelinePass { z.makeRenderTextures(delegate.mySize!) } }
      }
    */
      
//      for (x, mm) in pipelinePasses.enumerated() {
//        mm.makeEncoder(commandBuffer, scale, x == 0, delegate: delegate)
//      }
      
      // =========================================================================
      
      
      
      
      var rt : MTLTexture?
      
      //    if let frpp = config.pipelinePasses.last as? RenderPipelinePass {
      rt = self.renderPassDescriptor(kk.mySize!).colorAttachments[0].resolveTexture //  frpp.resolveTextures.1
      
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
      Task.detached {
      await MainActor.run {
        commandBuffer.commit()
      }
      }
    }
 
  */
  

    /// This is the CPU overlay on the initialization buffer
//    var inbuf : MyMTLStruct!

    /// this is the clear color for alpha blending?
//    var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )

//    /* private */ var cached : [IdentifiableView]?
    //  private var renderManager : RenderManager

//    var pipelinePasses : [RenderPipelinePass] = []
    var fragmentTextures : [TextureParameter] = []

//    /* private */ var myOptions : MyMTLStruct!
//    /* private  */ var dynPref : DynamicPreferences? // need to hold on to this for the callback
    /* internal */ /* private */ // var shaderName : String
    var computeBuffer : MTLBuffer?

    //  var videoNames : [VideoSupport] = []
    var webcam : WebcamSupport?

    /** This sets up the initializer by finding the function in the shader,
     using reflection to analyze the types of the argument
     then setting up the buffer which will be the "preferences" buffer.
     It would be the "Uniform" buffer, but that one is fixed, whereas this one is variable -- so it's
     just easier to make it a separate buffer
     */

    func buildImageWells() -> [IdentifiableView] {
      var res = [IdentifiableView]()
      let a = ImageStrip(texes: Binding.init(get: { return self.fragmentTextures } , set: { self.fragmentTextures = $0 }))
      res.append( IdentifiableView(id: "imageStrip", view: AnyView(a)))
      return res
    }

    // this is getting called during onTapGesture in LibraryView -- when I'm launching the ShaderView
    override func buildPrefView() -> [IdentifiableView] {
      if let z = cached { return z }
      if let mo = myOptions {
        let a = DynamicPreferences.init(myName)
        dynPref = a
        let c = buildImageWells()
//        let d = IdentifiableView(id: "sources", view: AnyView(SourceStrip()))

        cached = c + a.buildOptionsPane(mo)
        return cached!
      }
      return []
    }
    
    override func getClearColor(_ bst : MyMTLStruct) {
      guard let bb = bst["clearColor"] else { return }
      let v : SIMD4<Float> = bb.getValue()
      self.clearColor = v
    }

    func processWebcam(_ bst : MyMTLStruct ) {
     if let _ = bst["webcam"] {
       webcam = WebcamSupport(camera: "FIXME")
     }
     }

    /*
     func purge() {
     _videoNames.forEach {
     $0.endProcessing()
     }
     _videoNames = []
     }
     */
    
    override func processArguments(_ bst : MyMTLStruct ) {

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
    
    /*  func processVideos(_  bst: MyMTLStruct ) {
     _videoNames = []
     if let bss = bst.getStructArray("videos") {
     for bb in bss {
     if let jj = bb.getString(),
     let ii = Bundle.main.url(forResource: jj, withExtension: nil, subdirectory: "videos") {
     // print("appending \(jj) for \(self.shaderName ?? "" )")
     _videoNames.append( VideoSupport( ii ) )
     }
     }
     }
     }
     */

    func processTextures(_ bst : [MTLArgument] ) {
      for a in bst {
        if let b = TextureParameter(a, 0, getTexture(fragmentTextures.count), textureKey(fragmentTextures.count), id: fragmentTextures.count) {
          fragmentTextures.append(b)
        }
      }
    }
    
    override  func justInitialization() {
      let nam = myName + "_InitializeOptions"
      guard let initializationProgram = functionMaps["Shaders"]!.find( nam ) else {
        print("no initialization program for \(self.myName)")
        return
      }
      let cpld = MTLComputePipelineDescriptor()
      cpld.computeFunction = initializationProgram

      let commandBuffer = commandQueue.makeCommandBuffer()!
      commandBuffer.label = "Initialize command buffer for \(self.myName) "


      var cpr : MTLComputePipelineReflection?
      do {
        let initializePipelineState = try device.makeComputePipelineState(function: initializationProgram,
                                                                          options:[.argumentInfo, .bufferTypeInfo], reflection: &cpr)


        // FIXME: I want the render pipeline metadata

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

        if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
          computeEncoder.label = "initialization and defaults encoder \(self.myName)"
          computeEncoder.setComputePipelineState(initializePipelineState)
  //        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
          computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)

          let ms = MTLSize(width: 1, height: 1, depth: 1);
          computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
          computeEncoder.endEncoding()
        }
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted() // I need these values to proceed
      } catch {
        os_log("%s", type:.fault, "failed to initialize pipeline state for \(myName): \(error)")
        return
      }

      // at this point, the initialization (preferences) buffer has been set
      if let gg = cpr?.arguments.first(where: { $0.name == "in" }) {
        inbuf = MyMTLStruct.init(initializationBuffer, gg)
        processArguments(inbuf)
      }
    }

    /** this calls the GPU initialization routine to get the initial default values
     Take the contents of the buffer and save them as UserDefaults
     If the UserDefaults were previously set, ignore the results of the GPU initialization.

     This should only be called once at the beginning of the render -- when the view is loaded
     */

    func resetTarget() {
//      pipelinePasses = []
      fragmentTextures = []
    }

    func setupPipelines() {
//      pipelinePasses = []


      fragmentTextures = []

/*      if let vertexProgram = currentVertexFn(""),
         let fragmentProgram = currentFragmentFn(""),
         let p = RenderPipelinePass(
          label: "\(myName)",
          viCount: (4, 1),
          flags: 0,
          //          canvasSize: canvasSize,
          topology: .triangleStrip,
          computeBuffer : nil,
          functions: (vertexProgram, fragmentProgram)
         ) {
        pipelinePasses.append(p)
        // FIXME: put me back?
        // lastRender = p.resolveTextures.1
      } else {
        os_log("failed to create render pipeline pass for %s", type:.error, myName)
        return
      }
 */
    }
    
    // s should be "Shaders"
  /*
  private func currentVertexFn(_ s : String, _ sfx : String) -> MTLFunction? {
      let lun = "\(myName)___\(sfx)___Vertex"
      if let z = functionMaps[s]!.find(lun) { return z }
      return functionMaps[s]!.find("flatVertexFn")!
    }

  private func currentFragmentFn(_ s : String, _ sfx : String) -> MTLFunction? {
      let lun = "\(myName)___\(sfx)___Fragment"
      if let z = functionMaps[s]!.find(lun) { return z }
      return functionMaps[s]!.find("passthruFragmentFn")!
    }
  */

  func textureKey(_ z : Int) -> String {
    return "\(self.myName).texture.\(z)"
  }

  func getTexture(_ z : Int) -> XImage {
    if let z = UserDefaults.standard.data(forKey: textureKey(z) ) {
      var isStale = false
      if let bmu = try? URL(resolvingBookmarkData: z, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
        if (!isStale) {
          if bmu.startAccessingSecurityScopedResource() {
            defer { bmu.stopAccessingSecurityScopedResource() }
            if let i = XImage.init(contentsOf: bmu) {
              return i
            }
          }
        }
      }
    }
    return XImage.init(named: ["london", "flagstones", "water", "wood", "still_life"][z % 5] )!

  }


    
}

