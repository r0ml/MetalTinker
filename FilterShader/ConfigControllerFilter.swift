
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

class ConfigControllerFilter : ConfigController {

  required init(_ x : String) {
    print("filter subclass \(x)")
    super.init(x)
//    empty = XImage(named: "BrokenImage")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    // textureThumbnail = Array(repeating: nil, count: numberOfTextures)
    // inputTexture = Array(repeating: nil, count: Shader.numberOfTextures)

    // doInitialization()
  }

  
}
