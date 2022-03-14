
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit

final class ShaderTwo : Shader {
  typealias Config = ConfigController
  
  var myName : String
  var config : Config
  
  func setupFrame(_ t : Times) {
  }
  
  func startRunning() {
    
  }
  
  required init(_ s : String ) {
    print("ShaderTwo init \(s)")
    self.myName = s
    self.config = ConfigController(s)
  }

  var depthStencilState : MTLDepthStencilState?
  
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
  
  var textureLoader = MTKTextureLoader(device: device)
    
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
    for (i,v) in config.fragmentTextures.enumerated() {
      if let vs = v.video {
        config.fragmentTextures[i].texture = vs.readBuffer(times.currentTime) //     v.prepare(stat, currentTime - startTime)
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
  
  
  func doConfig() {
    Task.detached {
      await self.config.doInitialization()
      
      let depthStencilDescriptor = MTLDepthStencilDescriptor()
      depthStencilDescriptor.depthCompareFunction = .less
      depthStencilDescriptor.isDepthWriteEnabled = true // I would like to set this to false for triangle blending
      self.depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
  }
  

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
    func draw(in viewx: MTKView, delegate : MetalDelegate<ShaderTwo>) {
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
  
  
  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering
  func doRenderEncoder(
    _ xview : MTKView?,               // the MTKView if this is rendering to a view, otherwise I need the MTLRenderPassDescriptor
    delegate : MetalDelegate<ShaderTwo>,
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
      Task.detached {
      await MainActor.run {
        commandBuffer.commit()
      }
      }
    }
 
  
    
}
