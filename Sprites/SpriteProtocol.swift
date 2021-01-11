// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SpriteKit

// ==========================================================================

var spritery : Dictionary<String, Dictionary<String, SKScene>> = {
  var a = Dictionary<String, Dictionary<String, SKScene>>()

  a["SimpleSprite"] = register( [Simple3() ] )

//  a["3d scene"] = register( [] )
//  a["Shapes3d"] = register( [] )
//  a["Spheres"] = register( [] )

  return a
}()

// ==========================================================================

func register(_ dd : [SKScene]) -> Dictionary<String, SKScene> { // _ d : inout Dictionary<String, SceneProtocol>) {
  var b = Dictionary<String, SKScene>()
  dd.forEach { d in
    let a = String(describing: type(of: d))
    b[a] = d
  }
  return b
}
