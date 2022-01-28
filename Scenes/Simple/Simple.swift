// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit

class Simple : T3SCNScene {
  override var group : String { get  { "Simple" } }
  
  required init() {
    super.init()
    let mat = SCNMaterial()
    mat.diffuse.contents = XColor.red
    let a = SCNSphere(radius: 0.5)
    a.materials = [mat]
    let na = SCNNode(geometry: a)

    let b = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 1)
    let mat2 = SCNMaterial()
    mat2.diffuse.contents = XColor.blue
    b.materials = [mat2]
    let nb = SCNNode(geometry: b)

    self.rootNode.addChildNode(na)
    self.rootNode.addChildNode(nb)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
