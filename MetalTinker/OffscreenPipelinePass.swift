
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os

class OffscreenPipelinePass : PipelinePass {
  var size : (Int, Int)
  var flags : Int32
  var pipelineState : MTLRenderPipelineState
  var computeBuffer : MTLBuffer?
  var texture : MTLTexture
  var resolveTextures : (MTLTexture, MTLTexture)
  var topology : MTLPrimitiveType
  var label: String

  init?(label : String,
       size: (Int, Int), flags: Int32,
       topology: MTLPrimitiveType,
       computeBuffer : MTLBuffer?,
       functions f: (MTLFunction, MTLFunction)) {
    self.size = size
    self.flags = flags
    self.topology = topology
    self.computeBuffer = computeBuffer
    self.label = label

    if let rpp = setupRenderPipeline(vertexFunction: f.0, fragmentFunction: f.1, topology: topology),
      let ts = makeRenderPassTexture(label, size: CGSize(width: size.0, height: size.1)) {

      pipelineState = rpp
      texture = ts.0
      resolveTextures = (ts.1, ts.2)
    } else {
      return nil
    }

  }

  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ rpd: MTLRenderPassDescriptor, _ scale : CGFloat, _ rm : RenderManager, _ stat : Bool, _ isFirst : Bool) {
    for i in 0..<4 {
      // FIXME: here is where I look at rpp.flags
      rpd.colorAttachments[i].loadAction =  isFirst ? .clear : .load // xx == 0 ? .clear : .load
    }

    rm.renderToScreen(stat, commandBuffer: commandBuffer, topology: topology, rpp: self, rpd: rpd, rps : pipelineState,  scale: Int(scale), vertexCount: size.0, instanceCount: size.1 , computeBuffer: self.computeBuffer )
  }
}
    private func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?, topology: MTLPrimitiveType ) -> MTLRenderPipelineState? {
      // ============================================
      // this is the actual rendering fragment shader

      let psd = MTLRenderPipelineDescriptor()

      psd.vertexFunction = vertexFunction

      psd.fragmentFunction = fragmentFunction
      psd.colorAttachments[0].pixelFormat = thePixelFormat

      // FIXME: if I need additional attachments for renderPasses
      /*  for i in 1..<numberOfRenderPasses {
       psd.colorAttachments[i].pixelFormat = theOtherPixelFormat
       }
       */

      psd.isAlphaToOneEnabled = false
      psd.colorAttachments[0].isBlendingEnabled = true
      psd.colorAttachments[0].alphaBlendOperation = .add
      psd.colorAttachments[0].rgbBlendOperation = .add
      psd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha // I would like to set this to   .one   for some cases
      psd.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
      psd.colorAttachments[0].destinationRGBBlendFactor = .destinationAlpha // .oneMinusSourceAlpha // I would like to set this to  .one for some cases
      psd.colorAttachments[0].destinationAlphaBlendFactor = .destinationAlpha // .oneMinusSourceAlpha

      psd.depthAttachmentPixelFormat =  .depth32Float   // metalView.depthStencilPixelFormat

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

          return try device.makeRenderPipelineState(descriptor: psd)
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


