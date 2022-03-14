
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os

class BlitPipelinePass : PipelinePass {
  var inTexture : MTLTexture // this is the output texture
  var outTexture : MTLTexture
  var label: String

  init?(label: String,
        input: MTLTexture,
        output: MTLTexture) {
    self.label = label
    self.inTexture = input
    self.outTexture = output
  }

  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat, /* _ rm : RenderManager, */ 
                   _ isFirst: Bool,
                   delegate: MetalDelegate
  ) {
//                   _ stat : Bool) {


    let bce = commandBuffer.makeBlitCommandEncoder()!
      bce.copy(from: inTexture, to: outTexture)
      bce.endEncoding()
  }
}

