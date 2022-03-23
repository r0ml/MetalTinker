
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os
import SwiftUI

final class ShaderFilter : Shader {

  static var function = Function("Filters")
  var myName : String
  
  func setupFrame(_ t : Times) {
    
  }
  
  required init(_ s : String ) {
    print("ShaderFilter init \(s)")
    myName = s

    self.doInitialization()
  }

  private func currentFragmentFn() -> MTLFunction? {
    let lun = "\(myName)______Fragment"
    if let z = Self.function.find(lun) { return z }
    return Self.function.find("passthruFragmentFn")!
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

  
  
  
  
  
  
  
  
  
  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering
  func doRenderEncoder(
    _ xview : MTKView,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    _ rpd : MTLRenderPassDescriptor,
    delegate : MetalDelegate<ShaderFilter>,
    _ f : ((MTLTexture?) -> ())? ) { // for off-screen renderings, use a callback function instead of a semaphore?
      
      
      var scale : CGFloat = 1
      
      // FIXME: what is this in iOS land?  What is it in mac land?
#if os(macOS)
        let eml = NSEvent.mouseLocation
        let wp = viewx.window!.convertPoint(fromScreen: eml)
        let ml = viewx.convert(wp, from: nil)
        
        if xview.isMousePoint(ml, in: viewx.bounds) {
          delegate.setup.mouseLoc = ml
        }
        
        scale = xview?.window?.screen?.backingScaleFactor ?? 1
#endif
      
      // Set up the command buffer for this frame
      let  commandBuffer = commandQueue.makeCommandBuffer()!
      commandBuffer.label = "Render command buffer for \(self.myName)"
      
      // load the current time video frames
      
      // I've accidentally loaded up the textures during setup....
      
      makeEncoder(commandBuffer, scale, rpd, delegate: delegate)
      
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
      
      
      if let c = xview.currentDrawable {
        commandBuffer.present(c)
      }
      
      // without this, I get complaints about UI on background thread when I attempt to debug
      Task.detached {
        await MainActor.run {
          commandBuffer.commit()
        }
      }
    }

  
  
  func renderPassDescriptor(_ mySize : CGSize) -> MTLRenderPassDescriptor {
    if let rr = _renderPassDescriptor,
       mySize == _mySize {
      return rr }
    let k = makeRenderPassDescriptor(label: "render output", size: mySize)
    _renderPassDescriptor = k
    _mySize = mySize
    return k
  }
  
  var _renderPassDescriptor : MTLRenderPassDescriptor?
  var _mySize : CGSize?
  
  
  
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
      //      } else {
      //        self.isRunning = false // if I'm not going to set up the gpuSemaphore signal -- time to admit that I must be bailed
      //        delegate.gpuSemaphore.signal()
      //      }
    }
  }


  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat,
                   _ rpd : MTLRenderPassDescriptor,
                   delegate : MetalDelegate<ShaderFilter>) {


//    let rpd = delegate.shader.renderPassDescriptor(delegate.mySize!)

    // to get the running shader to match the preview?
    // FIXME: do I have clearColor?
    //    if let cc = rm.metalView?.clearColor {
    //      rpd.colorAttachments[0].clearColor = cc
    //      rpd.colorAttachments[0].loadAction = .clear
    //    }

    // FIXME: put me back
    //  let c = config.clearColor
    //  let ccc = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))

    // for preview, I make the clearColor have alpha of 1 so that it becomes the background.
    // FIXME: put me back
    //   rpd.colorAttachments[0].clearColor =  ccc

    //???
    //    rpd.colorAttachments[0].loadAction =  .clear

      // FIXME: put me back
      //   rpd.colorAttachments[i+1].clearColor =  ccc


    //    renderToScreen(stat, commandBuffer: commandBuffer, topology: topology, rpp: self, rpd: rpd, rps : pipelineState,  scale: Int(scale), vertexCount: viCount.0, instanceCount: viCount.1 , computeBuffer: self.computeBuffer )
    //  }


    // texture map:
    // 0 -> numberOfTextures (6) for inputs
    // 10 -> 10+numberOfRenderPasses (4)?  -- each render pass
    // 20 -> 20+numberOfCubes (2)? -- for 3d textures
    // 30 -> 30+numberOfRenderPasses (4)? -- outputs for each render pass

    // 8 and 9 for renderPass Input and Output -- but that is obsolete
    // 50 -> 50+numberOfVideos (2)? -- for video streaming?
    //
    //  func renderToScreen(_ stat : Bool, commandBuffer : MTLCommandBuffer, topology : MTLPrimitiveType,
    //                      rpp : RenderPipelinePass,
    //                      rpd : MTLRenderPassDescriptor, rps : MTLRenderPipelineState, scale : Int,
    //                      vertexCount : Int, instanceCount : Int, computeBuffer : MTLBuffer? ) {

    let sz = CGSize(width : rpd.colorAttachments[0].texture!.width /* / scale */ ,
                    height: rpd.colorAttachments[0].texture!.height /* / scale */ )

    delegate.setup.setupUniform( size: sz, scale: Int(scale), uniform: delegate.shader.uniformBuffer!, times: delegate.times )

    /*
    // I do this to clear out the renderInput textures
    if (delegate.setup.iFrame < 1) {

      if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.endEncoding()
      }

    }
*/


    // FIXME: crashes here all the time
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

      renderEncoder.setRenderPipelineState(pipelineState)

      // This sets up the drawable size?
      // FIXME: do I need this?
      /*
       if let v = delegate.shader.metalView {
       // FIXME:
       // did the drawableSize change since the last time?
       sz = v.drawableSize
       }*/

      // A filter render encoder takes a single instance of a rectangle (4 vertices) which covers the input.
      renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
      renderEncoder.endEncoding()
    }
  }

  // let's assume this is where the shader starts running, so shader initialization should happen here.
  func startRunning() {
    Task {
      // self.doInitialization()
      webcam?.startCapture()
    }
  }
  
  var pipelineState : MTLRenderPipelineState!
  var metadata : MTLRenderPipelineReflection!

  var renderInput : [(MTLTexture, MTLTexture, MTLTexture)] = []

  func resize(_ canvasSize: CGSize) {
    // FIXME: put me back
    /*
     if let ts = makeRenderPassTexture(self.label, size: canvasSize) {
     texture = ts.0
     resolveTextures = (ts.1, ts.2)
     }
     renderInput = renderInput.compactMap { _ in makeRenderPassTexture(label, size: canvasSize) }
     renderPassDescriptor.colorAttachments[0].texture = texture
     renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTextures.1 //  device.makeTexture(descriptor: xostd)


     let td = MTLTextureDescriptor()
     td.textureType = .type2DMultisample
     td.pixelFormat = .depth32Float
     td.storageMode = .private
     td.usage = [.renderTarget, .shaderRead]
     td.width = Int(canvasSize.width)  // should be the colorAttachments[0]  size
     td.height = Int(canvasSize.height)

     td.sampleCount = multisampleCount

     let dt = device.makeTexture(descriptor: td)

     //    depthAttachmentDescriptor.clearDepth = 1
     depthAttachmentDescriptor.texture = dt
     //    depthAttachmentDescriptor.loadAction = .clear
     */

  }
  
  /*
   func makeEncoder(_ commandBuffer : MTLCommandBuffer,
   _ scale : CGFloat,
   _ isFirst : Bool, delegate : MetalDelegate<ShaderTwo>) {


   let config = delegate.shader.config

   // This statement overrides the render pass descriptor with the onscreen frameBuffer if one exists -- otherwise it is using the offscreen texture
   var rpd : MTLRenderPassDescriptor

   //    if !stat {
   // FIXME: put me back
   //    rpd = delegate.shader.metalView?.currentRenderPassDescriptor ?? delegate.shader.renderPassDescriptor(delegate.mySize!)
   rpd = delegate.shader._renderPassDescriptor!

   //    } else {
   //      rpd = rm.renderPassDescriptor
   //    }

   // If I need depthing....
   // rpd.depthAttachment = depthAttachmentDescriptor
   // depth texture set up

   // to get the running shader to match the preview?
   // FIXME: do I have clearColor?
   //    if let cc = rm.metalView?.clearColor {
   //      rpd.colorAttachments[0].clearColor = cc
   //      rpd.colorAttachments[0].loadAction = .clear
   //    }

   // FIXME: put me back
   //  let c = config.clearColor
   //  let ccc = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))

   // for preview, I make the clearColor have alpha of 1 so that it becomes the background.
   // FIXME: put me back
   //   rpd.colorAttachments[0].clearColor =  ccc
   rpd.colorAttachments[0].loadAction = isFirst ? .clear : .load

   for i in 0..<renderInput.count {
   // FIXME: here is where I look at rpp.flags
   rpd.colorAttachments[i+1].texture = renderInput[i].0
   rpd.colorAttachments[i+1].resolveTexture = renderInput[i].2
   rpd.colorAttachments[i+1].loadAction =  delegate.setup.iFrame < 1 ? .clear : .load // xx == 0 ? .clear : .load
   rpd.colorAttachments[i+1].storeAction = .storeAndMultisampleResolve

   // FIXME: put me back
   //   rpd.colorAttachments[i+1].clearColor =  ccc

   }

   //    renderToScreen(stat, commandBuffer: commandBuffer, topology: topology, rpp: self, rpd: rpd, rps : pipelineState,  scale: Int(scale), vertexCount: viCount.0, instanceCount: viCount.1 , computeBuffer: self.computeBuffer )
   //  }


   // texture map:
   // 0 -> numberOfTextures (6) for inputs
   // 10 -> 10+numberOfRenderPasses (4)?  -- each render pass
   // 20 -> 20+numberOfCubes (2)? -- for 3d textures
   // 30 -> 30+numberOfRenderPasses (4)? -- outputs for each render pass

   // 8 and 9 for renderPass Input and Output -- but that is obsolete
   // 50 -> 50+numberOfVideos (2)? -- for video streaming?
   //
   //  func renderToScreen(_ stat : Bool, commandBuffer : MTLCommandBuffer, topology : MTLPrimitiveType,
   //                      rpp : RenderPipelinePass,
   //                      rpd : MTLRenderPassDescriptor, rps : MTLRenderPipelineState, scale : Int,
   //                      vertexCount : Int, instanceCount : Int, computeBuffer : MTLBuffer? ) {

   var sz = CGSize(width : rpd.colorAttachments[0].texture!.width /* / scale */ ,
   height: rpd.colorAttachments[0].texture!.height /* / scale */ )

   delegate.setup.setupUniform( size: sz, scale: Int(scale), uniform: delegate.uniformBuffer, times: delegate.times )

   // I do this to clear out the renderInput textures
   if (delegate.setup.iFrame < 1) {

   if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
   renderEncoder.setRenderPipelineState(pipelineState)
   renderEncoder.endEncoding()
   }

   if let be = commandBuffer.makeBlitCommandEncoder() {
   for ri in renderInput {
   be.copy(from: ri.2, to: ri.1)
   be.generateMipmaps(for: ri.1)
   }

   // FIXME: only do this on request?
   /*        for x in rm.videoTexture {
    if let x = x { be.generateMipmaps(for: x) }
    }
    */
   be.endEncoding()
   }
   }



   // FIXME: crashes here all the time
   // texture and resolveTexture size mismatch    during resize
   if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
   renderEncoder.label = "render encoder"

   // if the low order bit of flags is set -- this is a 2d (blended) render
   if ( (flags & 1) == 1) {
   } else {
   renderEncoder.setDepthStencilState(delegate.shader.depthStencilState)
   }
   renderEncoder.setVertexBuffer(delegate.uniformBuffer, offset: 0, index: uniformId)
   renderEncoder.setVertexBuffer(config.initializationBuffer, offset: 0, index: kbuffId)
   renderEncoder.setVertexBuffer(computeBuffer, offset: 0, index:computeBuffId)

   renderEncoder.setFragmentBuffer(delegate.uniformBuffer, offset: 0, index: uniformId)
   renderEncoder.setFragmentBuffer(config.initializationBuffer, offset: 0, index: kbuffId)
   for i in 0..<config.fragmentTextures.count {
   if config.fragmentTextures[i].texture == nil {
   config.fragmentTextures[i].texture = config.fragmentTextures[i].image.getTexture(delegate.shader.textureLoader, mipmaps: true)
   }
   renderEncoder.setFragmentTexture( config.fragmentTextures[i].texture, index: config.fragmentTextures[i].index)
   }

   renderEncoder.setFragmentBuffer(computeBuffer, offset: 0, index:computeBuffId)

   renderEncoder.setRenderPipelineState(pipelineState)

   // This sets up the drawable size?
   // FIXME: do I need this?
   /*
    if let v = delegate.shader.metalView {
    // FIXME:
    // did the drawableSize change since the last time?
    sz = v.drawableSize
    }*/

   switch( topology) {
   case .triangleStrip: renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: viCount.0, instanceCount: viCount.1)
   case .triangle: renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: viCount.0, instanceCount: viCount.1)
   case .line: renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: viCount.0, instanceCount: viCount.1)
   case .point: renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: viCount.0, instanceCount: viCount.1)
   default:
   os_log("unsupported topology", type: .error)
   }

   renderEncoder.endEncoding()

   if renderInput.count > 0,
   let be = commandBuffer.makeBlitCommandEncoder() {
   for ri in renderInput {
   be.copy(from: ri.2, to: ri.1)
   be.generateMipmaps(for: ri.1)
   }
   be.endEncoding()
   }
   }
   }
   */

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
        var res = try device.makeRenderPipelineState(descriptor: psd, options: [.argumentInfo, .bufferTypeInfo], reflection: &metadata)
        if let m = metadata {

          /*
          if let ri = m.fragmentArguments?.first(where: {$0.name == "renderInput"}) {
            // if I have an array length for renderInputs, I need to create output attachments and renderInputs to match
            let mc  = ri.arrayLength
            for i in 0..<mc {
              psd.colorAttachments[i+1].pixelFormat = thePixelFormat //  theOtherPixelFormat
            }
            // do it again because I had to update the pixel formats
            res = try device.makeRenderPipelineState(descriptor: psd)
          } */
          
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

  
  // Config Controller
  /// This buffer is known as in on the metal side
  public var initializationBuffer : MTLBuffer!
  /// This is the CPU overlay on the initialization buffer
  var inbuf : MyMTLStruct!

  /// this is the clear color for alpha blending?
  var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )
  private var cached : [IdentifiableView]?

  var fragmentTextures : [TextureParameter] = []

  private var myOptions : MyMTLStruct!
  private  var dynPref : DynamicPreferences? // need to hold on to this for the callback
  private var computeBuffer : MTLBuffer?

  //  var videoNames : [VideoSupport] = []
  var webcam : WebcamSupport?

  var uniformBuffer : MTLBuffer?

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
  func buildPrefView() -> [IdentifiableView] {
    if let z = cached { return z }
    if let mo = myOptions {
      let a = DynamicPreferences.init(myName)
      dynPref = a
      let c = buildImageWells()
      let d = IdentifiableView(id: "sources", view: AnyView(SourceStrip()))

      cached = [d] + c + a.buildOptionsPane(mo)
      return cached!
    }
    return []
  }

  func getClearColor(_ bst : MyMTLStruct) {
    guard let bb = bst["clearColor"] else { return }
    let v : SIMD4<Float> = bb.getValue()
    self.clearColor = v
  }

  func processWebcam(_ bst : MyMTLStruct ) {
    if let _ = bst["webcam"] {
      webcam = WebcamSupport()
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
      if let b = TextureParameter(a, id: fragmentTextures.count) {
        fragmentTextures.append(b)
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

  func doInitialization( ) {

    let uniformSize : Int = MemoryLayout<Uniform>.stride
    let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
    uni.label = "uniform"
    uniformBuffer = uni
    fragmentTextures = []

    let vertexProgram = Self.function.find("flatVertexFn")
    let fragmentProgram = currentFragmentFn()

    if let rpp = setupRenderPipeline(vertexFunction: vertexProgram, fragmentFunction: fragmentProgram) {
      (self.pipelineState, self.metadata) = rpp
    }

    justInitialization()


    //  await setupPipelines()
    let aa = metadata
    let bb = aa?.fragmentArguments
    
    if let a = bb {
      processTextures(a)
    }
    getClearColor(inbuf)
  }


  func justInitialization() {
    // await super.justInitialization()
    let nam = myName + "InitializeOptions"
    guard let initializationProgram = Self.function.find( nam ) else {
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
}

