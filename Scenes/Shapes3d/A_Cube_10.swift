
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit

class A_Cube_10 : T1SCNScene {
  override var group : String { get { "Shapes3d" } }

  required init() {
    super.init()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw() {
    self.reset()

    let b = SCNBox.init(width: 1, height: 1, length: 1, chamferRadius: 0)
    let mat2 = SCNMaterial()
    mat2.diffuse.contents = XColor.blue
    mat2.lightingModel = .phong
    b.materials = [mat2]
    let nb = SCNNode(geometry: b)
    let rr = SCNQuaternion(x: 0.2, y: 0.3, z: 0.5, w: 1)
    nb.rotate(by: rr, aroundTarget: SCNVector3(x: 0, y: 0, z: 0))

    let c = SCNLight()
    let nc = SCNNode()
    nc.light = c
    c.color = XColor.white
    c.type = .omni
    nc.position = SCNVector3(x: 1, y: 1, z: 3)

//    self.rootNode.addChildNode(na)a
    self.rootNode.addChildNode(nb)
    self.rootNode.addChildNode(nc)
    self.background.contents = XColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)

    let nba = SCNAction.rotateBy(x: 0, y: 0, z: 2 * CGFloat.pi, duration: 4) // (by: 2 * CGFloat.pi, around: SCNVector3(x: 0, y: 0, z: 1), duration: 4)
//    nb.runAction(nba)
    nb.runAction(SCNAction.repeatForever(nba))

  }
}
