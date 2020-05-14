
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os

struct Times {
  var currentTime : Double = now()
  var lastTime : Double = now()
  var startTime : Double = now()
}

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
                   _ scale : CGFloat, _ : RenderManager,
                   _ stat : Bool,
                   _ isFirst : Bool);
};


