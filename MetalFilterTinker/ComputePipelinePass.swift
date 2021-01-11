
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os

class ComputePipelinePass : PipelinePass {
//  var pms : MyMTLStruct?
  var viCount : (Int, Int)
  var label : String
  var flags : Int32
  var computeBuffer : MTLBuffer // if there is a compute buffer
  var pipelineState : MTLComputePipelineState

  init?(label: String, viCount: (Int, Int), flags: Int32, function f: MTLFunction) {
    self.viCount = viCount
    self.flags = flags
    self.label = label

    var ccpr : MTLComputePipelineReflection? = MTLComputePipelineReflection()
    do {
      let cpp = try device.makeComputePipelineState(function: f, options: [.argumentInfo, .bufferTypeInfo], reflection: &ccpr)
      if let gg = ccpr?.arguments.first(where: { $0.name == "computeBuffer"}),
        let cb = device.makeBuffer(length: gg.bufferDataSize) {
        self.computeBuffer = cb
        self.pipelineState = cpp
      } else {
        os_log("failed to allocate compute buffer for %s", type: .error, self.label)
        return nil
      }
    } catch let e {
      os_log("failed to create pipeline state for compute pipeline pass %s: %s", type: .error, self.label, e.localizedDescription)
      return nil
    }
  }

  func makeEncoder(_ commandBuffer : MTLCommandBuffer,
                   _ scale : CGFloat,
             //      _ rm: RenderManager,
             //      _ : Bool,
                   _ isFirst : Bool,
                   delegate : MetalDelegate) {
    guard let cps = commandBuffer.makeComputeCommandEncoder() else { return }
    guard let config = delegate.shader!.config else { return }
    cps.label = "compute pass for \(label)"
    cps.setComputePipelineState( pipelineState)
    cps.setBuffer(delegate.uniformBuffer, offset: 0, index: uniformId)
    cps.setBuffer(config.initializationBuffer, offset: 0, index: kbuffId)
    cps.setBuffer(computeBuffer, offset: 0, index: computeBuffId)
    cps.dispatchThreads( MTLSize(width: viCount.0, height: viCount.1, depth: 1), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1));
    cps.endEncoding()
  }
}

