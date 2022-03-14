
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

class ShaderTextures : Shader {
  func setupFrame(_ times: Times) {
  }
  
  static let numberOfTextures = 6

  typealias Config = ConfigController
  
  var myName : String
  
  required init(_ s : String ) {
    print("ShaderTextures init \(s)")
    myName = s
  }

}


