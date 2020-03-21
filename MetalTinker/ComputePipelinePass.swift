//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

import MetalKit
import os

class ComputePipelinePass : PipelinePass {
  var label : String
  var gridSize : (Int, Int)
  var flags : Int32
  var computeBuffer : MTLBuffer // if there is a compute buffer
  var pipelineState : MTLComputePipelineState

  init?(label: String, gridSize: (Int, Int), flags: Int32, function f: MTLFunction) {
    self.gridSize = gridSize
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
                   _ scale : CGFloat, _ rm: RenderManager, _ : Bool) {
    let cps = commandBuffer.makeComputeCommandEncoder();
    cps?.label = "compute pass for \(label)"
    cps?.setComputePipelineState( pipelineState)

    cps?.setBuffer(rm.uniformBuffer, offset: 0, index: uniformId)
    cps?.setBuffer(rm.config.initializationBuffer, offset: 0, index: kbuffId)

    cps?.setBuffer(computeBuffer, offset: 0, index: computeBuffId)

      //    cps?.setTexture(rm.config., index: <#T##Int#>)
    
    cps?.dispatchThreads( MTLSize(width: gridSize.0, height: gridSize.1, depth: 1), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1));
    cps?.endEncoding()
  }


}

