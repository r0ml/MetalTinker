// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit


// Renders a spritekit as the background for a SceneKit.  Hence, this is the same as just displaying the SpriteKit
class Simple6 : T1SCNScene {
  override var group : String { get { "Simple" } }

  required init() {
    super.init()
  }

  override func draw() {
    self.background.contents = Simple3()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
