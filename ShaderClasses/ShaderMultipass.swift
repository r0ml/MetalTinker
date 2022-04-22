
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit

final class ShaderMultipass : GenericShader {
 
    //  typealias Config = ConfigController
  
//  var myName : String
//  var config : Config
  
  required init(_ s : String ) {
    print("ShaderMultipass init \(s)")
    super.init(s)
//    config = Config(s)
  }

  override func draw(in viewx: MTKView, delegate : MetalDelegate) {
    
  }
  
  override func buildPrefView() -> [IdentifiableView] {
    return []
  }


}
