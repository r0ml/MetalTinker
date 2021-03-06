// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit

class Simple2 : T3SCNScene {
  override var group : String { get { "Simple" } }

  required init() {
    super.init()
    let mat = SCNMaterial()
    mat.diffuse.contents = NSColor.red
    let a = SCNBox.init(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.05)
    a.materials = [mat]
    let na = SCNNode(geometry: a)

    let b = SCNTorus.init(ringRadius: 0.6, pipeRadius: 0.2)
    let mat2 = SCNMaterial()
    mat2.diffuse.contents = NSColor.blue
    b.materials = [mat2]
    let nb = SCNNode(geometry: b)

    self.rootNode.addChildNode(na)
    self.rootNode.addChildNode(nb)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
