
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import SwiftUI

final class ShaderTextures : Shader {
  func setupFrame(_ times: Times) {
  }
  
  func draw(in viewx: MTKView, delegate: MetalDelegate<ShaderTextures>) {
  }
  
  static let numberOfTextures = 6

//  typealias Config = ConfigController
  
  var myName : String
//  var config : Config
  
  required init(_ s : String ) {
    print("ShaderTextures init \(s)")
    myName = s
 //   config = Config(s)
  }

  func startRunning() {
  }
  
  func buildPrefView() -> [IdentifiableView] {
    return []
  }
  
}


