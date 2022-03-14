
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit

final class ShaderFilter : Shader {
  typealias Config = ConfigControllerFilter

  var myName : String
  var config : Config
  
  func setupFrame(_ t : Times) {
    
  }
  
  required init(_ s : String ) {
    print("ShaderFilter init \(s)")
    myName = s
    config = Config(s)
  }

  var textureLoader = MTKTextureLoader(device: device)

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
    _ xview : MTKView?,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    delegate : MetalDelegate<ShaderFilter>,
    _ f : ((MTLTexture?) -> ())? ) { // for off-screen renderings, use a callback function instead of a semaphore?
      
      if delegate.uniformBuffer == nil { // notInitialized
        delegate.uniformBuffer = config.uniformBuffer
        // setupVideo()
      }
      
      var scale : CGFloat = 1
      
      // FIXME: what is this in iOS land?  What is it in mac land?
#if os(macOS)
      if let viewx = xview {let eml = NSEvent.mouseLocation
        let wp = viewx.window!.convertPoint(fromScreen: eml)
        let ml = viewx.convert(wp, from: nil)
        
        if viewx.isMousePoint(ml, in: viewx.bounds) {
          delegate.setup.mouseLoc = ml
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
      
        config.pipeline.makeEncoder(commandBuffer, scale, true, delegate: delegate)
      
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
      if let _ = viewx.currentRenderPassDescriptor {
        
        // to get the running shader to match the preview?
        // rpd.colorAttachments[0].clearColor = viewx.clearColor
        
        self.doRenderEncoder(viewx, delegate : delegate ) { _ in
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


  func makeEncoder<T:Shader>(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat,
                   delegate : MetalDelegate<T>) {


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
    rpd.colorAttachments[0].loadAction =  .clear

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

    }



    // FIXME: crashes here all the time
    // texture and resolveTexture size mismatch    during resize
    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder"

      renderEncoder.setFragmentBuffer(delegate.uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setFragmentBuffer(config.initializationBuffer, offset: 0, index: kbuffId)
      for i in 0..<config.fragmentTextures.count {
        if config.fragmentTextures[i].texture == nil {
          config.fragmentTextures[i].texture = config.fragmentTextures[i].image.getTexture(delegate.shader.textureLoader, mipmaps: true)
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

      
      renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: viCount.0, instanceCount: viCount.1)

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

  
  
  func startRunning() {
    config.webcam?.startCapture()
  }
}
