//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

import MetalKit
import os

class FilterPipelinePass : PipelinePass {
  var flags: Int32
  var pipelineState : MTLRenderPipelineState
  var otherPipelineState : MTLRenderPipelineState

  var texture : MTLTexture // this is the output texture
  var inputTexture : MTLTexture
  var label: String
  var isFinal = false

  init?(label: String,
        size: CGSize,
        flags: Int32,
        function f: MTLFunction,
        input: MTLTexture,
        isFinal: Bool) {
    self.flags = flags
    self.label = label
    self.inputTexture = input
    self.isFinal = isFinal

    let texo = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: theOtherPixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
    texo.textureType = .type2D
    texo.sampleCount = 1
    texo.usage = [.renderTarget, .shaderWrite, .shaderRead] // or just renderTarget -- because the next stage wants to read the texture
    texo.resourceOptions = .storageModePrivate
    if let tx = device.makeTexture(descriptor: texo)  {
      self.texture = tx
    } else {
      return nil
    }

    let psd = MTLRenderPipelineDescriptor()

    psd.vertexFunction = findFunction("flatVertexFn")
    psd.fragmentFunction = f
    psd.colorAttachments[0].pixelFormat = theOtherPixelFormat

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

    //              psd.depthAttachmentPixelFormat =  .depth32Float   // metalView.depthStencilPixelFormat



    // My choices are:
    // 1) Always be subpixel rendering or
    // 2) generate two pipeline states, and use the appropriate one.

    psd.sampleCount =  1
    psd.inputPrimitiveTopology = .triangle


    
    do {
      let jj = try device.makeRenderPipelineState(descriptor: psd)
      self.pipelineState = jj

      psd.sampleCount = multisampleCount
      let kk = try device.makeRenderPipelineState(descriptor: psd)
      self.otherPipelineState = kk
    } catch(let e) {
      os_log("failed to create render pipeline state for %s: %s", type: .error, self.label, e.localizedDescription )
      return nil
    }


  }

  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat, _ rm : RenderManager, _ stat : Bool) {

    // var sz = CGSize(width : rpd.colorAttachments[0].texture!.width /* / scale */ ,
    //  height: rpd.colorAttachments[0].texture!.height /* / scale */ )

    var rpd = MTLRenderPassDescriptor()
    let ps = isFinal && !stat ? otherPipelineState : pipelineState

    if isFinal && !stat,
      let pd = rm.metalView?.currentRenderPassDescriptor {

      // this zaps out depth processing for texture filters ....
      rm.metalView?.depthStencilPixelFormat = .invalid

      // If I get in here, then I'm picking up the metalview pipeline state -- which is anti-aliased
      // that means the output texture has a sampleCount of 4
      rpd = rm.metalView!.currentRenderPassDescriptor!


    } else {
      rpd.colorAttachments[0].texture = self.texture
      rpd.colorAttachments[0].storeAction = .store

      //    rpd.colorAttachments[0].resolveLevel = 0

      /*  let xostd = ostd
       xostd.textureType = .type2D
       xostd.sampleCount = 1
       xostd.usage = [.shaderRead ]  // .pixelFormatView?
       */
      // I need this if I'm creating a CGImage -- CIImage doesn't need it?
      // xostd.storageMode = .managed

      //  rpd.colorAttachments[0].resolveTexture = device.makeTexture(descriptor: xostd)

      let c = rm.config.clearColor

      // for preview, I make the clearColor have alpha of 1 so that it becomes the background.
      rpd.colorAttachments[0].clearColor =  MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))
      rpd.colorAttachments[0].loadAction = .clear // .load

    }

    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder for \(label)"

      //      renderEncoder.setFragmentBuffer(computeBuffer, offset: 0, index:computeBuffId)
      renderEncoder.setFragmentTexture(self.inputTexture, index: inputTextureId)
      renderEncoder.setRenderPipelineState(ps)
      renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
      renderEncoder.endEncoding()
    }
  }
}

