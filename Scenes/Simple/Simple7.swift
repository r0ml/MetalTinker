// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit
import MetalKit


// Renders a spritekit as the background for a SceneKit.  Hence, this is the same as just displaying the SpriteKit
class Simple7 : T3ShaderSCNScene {
  override var group : String { get { "Circles" } }

  required init() {
    super.init(shader: "Bubbles", library: "Circles")
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  required init(shader: String, library: String) {
    fatalError("init(shader:library:) has not been implemented")
  }
}

