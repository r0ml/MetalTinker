
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import SceneKit

final class ShaderMultipass : ShaderVertex {
 
    //  typealias Config = ConfigController
  
//  var myName : String
//  var config : Config
  
  required init(_ s : String ) {
    print("ShaderMultipass init \(s)")
    super.init(s)
//    config = Config(s)
  }

  override var myGroup : String {
    get { "Multipass" }
  }


  override func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?) -> (MTLRenderPipelineState, MTLRenderPipelineReflection, MTLRenderPipelineDescriptor)? {
    print("hunh")

    let a = super.setupRenderPipeline(vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)
    return a
  }

  override func doInitialization() {
    super.doInitialization()
  }

  override func justInitialization() {
    super.justInitialization()
  }
}
