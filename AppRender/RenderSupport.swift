
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os

protocol PipelinePass {
  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat,
                   _ isFirst : Bool,
                   delegate : MetalDelegate);
};


