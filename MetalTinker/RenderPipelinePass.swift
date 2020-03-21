//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

import MetalKit
import os

class RenderPipelinePass : PipelinePass {
  var viCount : (Int, Int)
  var flags : Int32
  var pipelineState : MTLRenderPipelineState
  var computeBuffer : MTLBuffer?
  var texture : MTLTexture
  var resolveTextures : (MTLTexture, MTLTexture)
  var topology : MTLPrimitiveType
  var label: String
  var renderPassDescriptor = MTLRenderPassDescriptor()
  var depthAttachmentDescriptor = MTLRenderPassDepthAttachmentDescriptor()
  var isFinal = false;
  var metadata : MTLRenderPipelineReflection

  var renderInput : [(MTLTexture, MTLTexture, MTLTexture)] = []

  func resize(_ canvasSize: CGSize) {
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

    td.sampleCount = 4

    let dt = device.makeTexture(descriptor: td)

//    depthAttachmentDescriptor.clearDepth = 1
    depthAttachmentDescriptor.texture = dt
//    depthAttachmentDescriptor.loadAction = .clear

  }

  init?(label : String,
        viCount: (Int, Int), flags: Int32,
        canvasSize : CGSize,
        topology: MTLPrimitiveType,
        computeBuffer : MTLBuffer?,
        functions f: (MTLFunction, MTLFunction),
        isFinal: Bool) {
    self.viCount = viCount
    self.flags = flags
    self.topology = topology
    self.computeBuffer = computeBuffer
    self.label = label
    self.isFinal = isFinal

    if let rpp = setupRenderPipeline(vertexFunction: f.0, fragmentFunction: f.1, topology: topology, isFinal: isFinal),
      let ts = makeRenderPassTexture(label, size: canvasSize) {

      (pipelineState, metadata) = rpp
      texture = ts.0
      resolveTextures = (ts.1, ts.2)



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
      //------------------------------------------------------------
      // texture on device to be written to..
      //------------------------------------------------------------

      //         let rpd = MTLRenderPassDescriptor()
      renderPassDescriptor.colorAttachments[0].texture = texture
      renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve

      renderPassDescriptor.colorAttachments[0].resolveLevel = 0

/*
      let xostd = ostd
      xostd.textureType = .type2D
      xostd.sampleCount = 1
      xostd.usage = [.shaderRead ]  // .pixelFormatView?
*/
      // I need this if I'm creating a CGImage -- CIImage doesn't need it?
      // xostd.storageMode = .managed

      renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTextures.1 //  device.makeTexture(descriptor: xostd)

      renderPassDescriptor.colorAttachments[0].loadAction = .clear // .load
//      let c = NSColor.black.withAlphaComponent(0.6) // .load
//      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)





      // set up the depth texture
      let td = MTLTextureDescriptor()
      td.textureType = .type2DMultisample
      td.pixelFormat = .depth32Float
      td.storageMode = .private
      td.usage = [.renderTarget, .shaderRead]
      td.width = Int(canvasSize.width)  // should be the colorAttachments[0]  size
      td.height = Int(canvasSize.height)

      td.sampleCount = 4

      let dt = device.makeTexture(descriptor: td)

      depthAttachmentDescriptor.clearDepth = 1
      depthAttachmentDescriptor.texture = dt
      depthAttachmentDescriptor.loadAction = .clear


    } else {
      return nil
    }

  }
  
  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat, _ rm : RenderManager, _ stat : Bool) {


    // This statement overrides the render pass descriptor with the onscreen frameBuffer if one exists -- otherwise it is using the offscreen texture
    let rpd = isFinal && !stat ? rm.metalView?.currentRenderPassDescriptor ?? renderPassDescriptor : renderPassDescriptor

    // If I need depthing....
    rpd.depthAttachment = depthAttachmentDescriptor
    // depth texture set up

    // to get the running shader to match the preview?
    if let cc = rm.metalView?.clearColor {
      rpd.colorAttachments[0].clearColor = cc
      rpd.colorAttachments[0].loadAction = .clear

    }

    let c = rm.config.clearColor
    let ccc = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: 1)

    // for preview, I make the clearColor have alpha of 1 so that it becomes the background.
    rpd.colorAttachments[0].clearColor =  ccc
    rpd.colorAttachments[0].loadAction = .clear

    for i in 0..<renderInput.count {
      // FIXME: here is where I look at rpp.flags
      rpd.colorAttachments[i+1].texture = renderInput[i].0
      rpd.colorAttachments[i+1].resolveTexture = renderInput[i].2
      rpd.colorAttachments[i+1].loadAction =  rm.setup.iFrame < 1 ? .clear : .load // xx == 0 ? .clear : .load
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

    rm.setup.setupUniform( size: sz, scale: Int(scale), stat: stat, uniform: rm.uniformBuffer, times: rm.times )

 /*   if (rm.setup.iFrame < 1) {
        if let be = commandBuffer.makeBlitCommandEncoder() {
           for ri in renderInput {
             be.copy(from: ri.1, to: ri.2)
           }
           be.endEncoding()
         }

    }
*/

// I do this to clear out the renderInput textures
    if (rm.setup.iFrame < 1) {

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
      for x in rm.videoTexture {
        if let x = x { be.generateMipmaps(for: x) }
      }
      be.endEncoding()
    }
    }



    // FIXME: crashes here all the time
    // texture and resolveTexture size mismatch    during resize
    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder"

      renderEncoder.setDepthStencilState(rm.depthStencilState)

      renderEncoder.setVertexBuffer(rm.uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setVertexBuffer(rm.config.initializationBuffer, offset: 0, index: kbuffId)
      renderEncoder.setVertexBuffer(computeBuffer, offset: 0, index:computeBuffId)

      renderEncoder.setFragmentBuffer(rm.uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setFragmentBuffer(rm.config.initializationBuffer, offset: 0, index: kbuffId)
      renderEncoder.setFragmentTextures(rm.config.inputTexture, range: inputTextureId..<inputTextureId + RenderManager.numberOfTextures)

      renderEncoder.setFragmentBuffer(computeBuffer, offset: 0, index:computeBuffId)

      // FIXME: how to set renderPassInputs?
      renderEncoder.setFragmentTextures(self.renderInput.map { $0.1 }, range: renderInputId..<(renderInputId+self.renderInput.count))


      renderEncoder.setFragmentTextures(rm.cubeTexture, range: cubeId..<(cubeId+RenderManager.numberOfCubes))
      renderEncoder.setFragmentTextures(rm.setup.textTextures, range: renderedTextsId..<(renderedTextsId+RenderManager.numberOfTexts))

      renderEncoder.setFragmentBuffers(rm.audioBuffer, offsets: Array(repeating: 0, count: RenderManager.numberOfSounds), range: audioBuffId..<(audioBuffId+RenderManager.numberOfSounds))
      renderEncoder.setFragmentBuffers(rm.fftBuffer, offsets: Array(repeating: 0, count: RenderManager.numberOfSounds), range: fftBuffId..<(fftBuffId+RenderManager.numberOfSounds))

      renderEncoder.setFragmentTextures(rm.videoTexture, range: videoId..<(videoId+RenderManager.numberOfVideos))
      if let wct = rm.webcamTexture {
        renderEncoder.setFragmentTexture(wct, index: webcamId)
      } else {
        renderEncoder.setFragmentTexture(nil, index: webcamId)
      }


      renderEncoder.setRenderPipelineState(pipelineState)

      // This sets up the drawable size?
      if let v = rm.metalView {
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


}
private func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?, topology: MTLPrimitiveType
  , isFinal: Bool) -> (MTLRenderPipelineState, MTLRenderPipelineReflection)? {
  // ============================================
  // this is the actual rendering fragment shader

  let psd = MTLRenderPipelineDescriptor()

  psd.vertexFunction = vertexFunction

  psd.fragmentFunction = fragmentFunction
  psd.colorAttachments[0].pixelFormat = isFinal ? thePixelFormat : theOtherPixelFormat


  psd.isAlphaToOneEnabled = false
  psd.colorAttachments[0].isBlendingEnabled = true
  psd.colorAttachments[0].alphaBlendOperation = .add
  psd.colorAttachments[0].rgbBlendOperation = .add
  psd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha // I would like to set this to   .one   for some cases
  psd.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
  psd.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha // I would like to set this to  .one for some cases
  psd.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

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
            psd.colorAttachments[i+1].pixelFormat = theOtherPixelFormat
          }
          // do it again because I had to update the pixel formats
          res = try device.makeRenderPipelineState(descriptor: psd)
        }



        return (res, m)
      }
    } catch let er {
      //          let m = "Failed to create render render pipeline state for \(self.label), error \(er.localizedDescription)"
      os_log("%s", type:.error, er.localizedDescription)
      return nil
    }
  } else {
    os_log("vertex or fragment function missing")
  }
  return nil

}


private func makeRenderPassTexture(_ nam : String, size: CGSize) -> (MTLTexture, MTLTexture, MTLTexture)? {
  let texd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: theOtherPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
  texd.textureType = .type2DMultisample
  texd.usage = [.renderTarget]
  texd.sampleCount = multisampleCount
  texd.resourceOptions = .storageModePrivate

  let texi = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: theOtherPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: true)
  texi.textureType = .type2D
  texi.usage = [.shaderRead]
  texi.resourceOptions = .storageModePrivate

  let texo = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: theOtherPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
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

