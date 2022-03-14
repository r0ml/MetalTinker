

// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#if os(macOS)
import AppKit
#endif

import MetalKit
import os

struct Uniform {
  var iDate : SIMD4<Float> = SIMD4<Float>(0,0,0,0)  // (year, month, day, time in seconds)
  var iMouse : SIMD2<Float> = SIMD2<Float>(0,0)     // mouse pixel coords
  var lastTouch : SIMD2<Float> = SIMD2<Float>(0,0)  // where the drag started (if buttons are down)
  var iResolution : SIMD2<Float> = SIMD2<Float>(0,0) // viewport resolution (in pixels)
  var keyPress : SIMD2<UInt32> = [0,0]         // the key which is down, and the key which was clicked
  var iFrame : Int32 = -1                      // shader playback frame
  var iTime : Float = 0                        // shader playback time (in seconds)
  var iTimeDelta : Float = Float(1)/Float(60)  // render time (in seconds)
  
  var mouseButtons : Int32 = 0
  var eventModifiers : Int32 = 0
}

class RenderSetup {
  var iFrame = -1
  var keyPress : SIMD2<UInt32> = [0,0]
  
  var mouseLoc : CGPoint = CGPoint(x: 800, y: 500)
  var lastTouch : CGPoint = CGPoint.zero
  var mouseButtons : Int = 0
  
  // ===========================================================================================================
  // below the line here is stuff that happens on every frame
  
  /** Sets the values for the Uniform value passed to shaders.
   Needs to be called for every frame */
  public func setupUniform(size: CGSize, scale : Int, uniform uni: MTLBuffer, times : Times) {
    let uniform = uni.contents().assumingMemoryBound(to: Uniform.self)
    
    iFrame += 1
    
#if os(macOS)
    let modifierFlags = NSEvent.modifierFlags
    //   let mouseButtons = NSEvent.pressedMouseButtons
#endif
    
    let w = Float(size.width)
    let h = Float(size.height)
    let s = Float(scale)
    uniform.pointee.iMouse    = SIMD2<Float>( s * Float(mouseLoc.x)  / w, 1 - s * Float(mouseLoc.y) / h )
    uniform.pointee.lastTouch = SIMD2<Float>( s * Float(lastTouch.x) / w, 1 - s * Float(lastTouch.y) / h )
    uniform.pointee.mouseButtons = Int32(mouseButtons)
    
#if os(macOS)
    uniform.pointee.eventModifiers = Int32(modifierFlags.rawValue)
#endif
    
    // Pass the key event in to the shader, then reset (so it only gets passed once)
    // when the key is released, event handling will so indicate.
    uniform.pointee.keyPress = self.keyPress
    self.keyPress.x = 0
    
    // set resolution and time
    uniform.pointee.iFrame = Int32(iFrame)
    uniform.pointee.iResolution = SIMD2<Float>(Float(size.width), Float(size.height))
    uniform.pointee.iTime = Float(times.currentTime - times.startTime)
    uniform.pointee.iTimeDelta = Float(times.currentTime - times.lastTime)
    
    // Set up iDate
    let _date = Date()
    let components = Calendar.current.dateComponents( Set<Calendar.Component>([.year, .month, .day, .hour, .minute,  .second]), from:_date)
    let d = components.second! + components.minute! * 60 + components.hour! * 3600;
    let d2 = Float(d) + Float(_date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1))
    if let y = components.year, let m = components.month, let d = components.day {
      uniform.pointee.iDate = SIMD4<Float>(Float(y), Float(m), Float(d), d2)
    }
    
    // Done.  Sync with GPU
    uni.didModifyRange(0..<uni.length)
  }
}





// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os

class RenderPipelinePass : PipelinePass {
  var viCount : (Int, Int)
  var flags : Int32
  var pipelineState : MTLRenderPipelineState
  var metadata : MTLRenderPipelineReflection

  var computeBuffer : MTLBuffer?

  var topology : MTLPrimitiveType
  var label: String

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

  init?(label : String,
        viCount: (Int, Int), // vertex count
        flags: Int32,
//        canvasSize : CGSize,
        topology: MTLPrimitiveType,
        computeBuffer : MTLBuffer?,
        functions f: (MTLFunction, MTLFunction)
  ) {
    self.viCount = viCount
    self.flags = flags
    self.topology = topology
    self.computeBuffer = computeBuffer
    self.label = label

    if let rpp = Self.setupRenderPipeline(vertexFunction: f.0, fragmentFunction: f.1, topology: topology, flags: flags) {
      (pipelineState, metadata) = rpp
    } else {
      return nil
    }
  }

  func makeRenderTextures(_ canvasSize : CGSize) {
      if let ri = metadata.fragmentArguments?.first(where: {$0.name == "renderInput"}) {
        // if I have an array length for renderInputs, I need to create output attachments and renderInputs to match
        let mc  = ri.arrayLength
        for _ in 0..<mc {
          if let z = makeRenderPassTexture(label, size: canvasSize) {
            renderInput.append(z)
          }
        }
      }

      // Should I reuse this texture ?  -- the preview is serialized....
      /*   var myt : MTLTexture

       let ostd = MTLTextureDescriptor.texture2DDescriptor(
       //        pixelFormat: .bgra8Unorm,
       pixelFormat: thePixelFormat,
       width: Int(canvasSize.width), // or I could always use 1280
       height: Int(canvasSize.height),  // or I could always use 720
       mipmapped: false)
       ostd.textureType = .type2DMultisample
       ostd.storageMode = .private
       ostd.sampleCount = multisampleCount
       ostd.usage = [.renderTarget ] // , .shaderWrite, .shaderRead ]   .pixelFormatView ?


       let ost = device.makeTexture(descriptor: ostd)
       ost?.label = "offscreen preview"

       myt = ost!
       */

      // makeRenderPassDescriptor

      // let depthAttachementDescriptor = makeDepthAttachmentDescriptor(size: canvasSize)

    }

  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat,
                   _ isFirst : Bool, delegate : MetalDelegate) {


    guard let config = delegate.shader.config else { return }

    // This statement overrides the render pass descriptor with the onscreen frameBuffer if one exists -- otherwise it is using the offscreen texture
    var rpd : MTLRenderPassDescriptor

//    if !stat {
    rpd = delegate.shader.metalView?.currentRenderPassDescriptor ?? delegate.shader.renderPassDescriptor(delegate.mySize!)
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

    let c = config.clearColor
    let ccc = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))

    // for preview, I make the clearColor have alpha of 1 so that it becomes the background.
    rpd.colorAttachments[0].clearColor =  ccc
    rpd.colorAttachments[0].loadAction = isFirst ? .clear : .load

    for i in 0..<renderInput.count {
      // FIXME: here is where I look at rpp.flags
      rpd.colorAttachments[i+1].texture = renderInput[i].0
      rpd.colorAttachments[i+1].resolveTexture = renderInput[i].2
      rpd.colorAttachments[i+1].loadAction =  delegate.setup.iFrame < 1 ? .clear : .load // xx == 0 ? .clear : .load
      rpd.colorAttachments[i+1].storeAction = .storeAndMultisampleResolve
      rpd.colorAttachments[i+1].clearColor =  ccc

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
      if let v = delegate.shader.metalView {
        // FIXME:
        // did the drawableSize change since the last time?
        sz = v.drawableSize
      }

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

static func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?, topology: MTLPrimitiveType
  , flags: Int32) -> (MTLRenderPipelineState, MTLRenderPipelineReflection)? {
  // ============================================
  // this is the actual rendering fragment shader

  let psd = MTLRenderPipelineDescriptor()

  psd.vertexFunction = vertexFunction

  psd.fragmentFunction = fragmentFunction
  psd.colorAttachments[0].pixelFormat = thePixelFormat

  let doesBlend = ((flags & 1) == 1)

  psd.isAlphaToOneEnabled = false
  psd.colorAttachments[0].isBlendingEnabled = true
  psd.colorAttachments[0].alphaBlendOperation = .add
  psd.colorAttachments[0].rgbBlendOperation = .add
  psd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha // I would like to set this to   .one   for some cases
  psd.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
  psd.colorAttachments[0].destinationRGBBlendFactor = doesBlend ? .destinationAlpha : .oneMinusSourceAlpha
  psd.colorAttachments[0].destinationAlphaBlendFactor = doesBlend ? .destinationAlpha : .oneMinusSourceAlpha

  psd.depthAttachmentPixelFormat =  .depth32Float   // metalView.depthStencilPixelFormat

  // FIXME: if I need additional attachments for renderPasses
  //   for i in 1 ..< numberOfRenderPasses {
  //    psd.colorAttachments[i].pixelFormat = theOtherPixelFormat
  //    }

  psd.sampleCount = multisampleCount

  switch(topology) {
  case .point:  psd.inputPrimitiveTopology = .point // got here for preview and actual
  case .line: psd.inputPrimitiveTopology = .line
  case .lineStrip: psd.inputPrimitiveTopology = .line
  case .triangle: psd.inputPrimitiveTopology = .triangle
  case .triangleStrip: psd.inputPrimitiveTopology = .triangle
  @unknown default:
    fatalError()
  }

  //    renderPipelineDescriptor = psd

  if psd.vertexFunction != nil && psd.fragmentFunction != nil {
    do {
      var metadata : MTLRenderPipelineReflection?
      var res = try device.makeRenderPipelineState(descriptor: psd, options: [.argumentInfo, .bufferTypeInfo], reflection: &metadata)
      if let m = metadata {

        if let ri = m.fragmentArguments?.first(where: {$0.name == "renderInput"}) {
          // if I have an array length for renderInputs, I need to create output attachments and renderInputs to match
          let mc  = ri.arrayLength
          for i in 0..<mc {
            psd.colorAttachments[i+1].pixelFormat = thePixelFormat //  theOtherPixelFormat
          }
          // do it again because I had to update the pixel formats
          res = try device.makeRenderPipelineState(descriptor: psd)
        }
        return (res, m)
      }
    } catch let er {
      // let m = "Failed to create render render pipeline state for \(self.label), error \(er.localizedDescription)"
      os_log("%s", type:.error, er.localizedDescription)
      return nil
    }
  } else {
    os_log("vertex or fragment function missing")
  }
  return nil
}

static func makeDepthAttachmentDescriptor(size canvasSize : CGSize) -> MTLRenderPassDepthAttachmentDescriptor {

  let depthAttachmentDescriptor = MTLRenderPassDepthAttachmentDescriptor()
  // set up the depth texture
  let td = MTLTextureDescriptor()
  td.textureType = .type2DMultisample
  td.pixelFormat = .depth32Float
  td.storageMode = .private
  td.usage = [.renderTarget, .shaderRead]
  td.width = Int(canvasSize.width)  // should be the colorAttachments[0]  size
  td.height = Int(canvasSize.height)

  td.sampleCount = 4 // should be multisampleCount -- but I can't see it

  let dt = device.makeTexture(descriptor: td)

  depthAttachmentDescriptor.clearDepth = 1
  depthAttachmentDescriptor.texture = dt
  depthAttachmentDescriptor.loadAction = .clear
  return depthAttachmentDescriptor
}

}






// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os


class PipelineState {
  var fragment : MTLRenderPipelineState?
  var kernel : MTLComputePipelineState?
  var isKernel : Bool { get { return kernel != nil } }
  var isFragment : Bool { get { return fragment != nil } }

  init(fragment: MTLRenderPipelineState) {
    self.fragment = fragment
    self.kernel = nil
  }

  init(kernel: MTLComputePipelineState) {
    self.kernel = kernel
    self.fragment = nil
  }
}

protocol PipelinePass {
  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat,
                   _ isFirst : Bool,
                   delegate : MetalDelegate);
};


