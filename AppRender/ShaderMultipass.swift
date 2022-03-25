
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit

final class ShaderMultipass : Shader {
  func setupFrame(_ times: Times) {
  }
  
  func startRunning() {
  }

  func stopRunning() {
    
  }
  
    //  typealias Config = ConfigController
  
  var myName : String
//  var config : Config
  
  required init(_ s : String ) {
    print("ShaderMultipass init \(s)")
    myName = s
//    config = Config(s)
  }

  func draw(in viewx: MTKView, delegate : MetalDelegate<ShaderMultipass>) {
    
  }
  
  func buildPrefView() -> [IdentifiableView] {
    return []
  }
  

}
