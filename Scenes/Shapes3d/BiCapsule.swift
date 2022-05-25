// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit

class BiCapsule : T1SCNScene {
  override var group : String { get { "Shapes3d" } }

  required init() {
    super.init()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw() {
/*    let mat = SCNMaterial()
    mat.diffuse.contents = XColor.red
    let a = SCNBox.init(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.05)
    a.materials = [mat]
    let na = SCNNode(geometry: a)
*/

    self.reset()
    let b = SCNCapsule.init(capRadius: 1, height: 7)
    let mat2 = SCNMaterial()
    mat2.diffuse.contents = XColor.blue
    mat2.ambient.contents = XColor.green
    mat2.emission.contents = XColor.red
    mat2.lightingModel = .phong
    b.materials = [mat2]
    let nb = SCNNode(geometry: b)
    nb.position = SCNVector3(x: -3, y: 0, z: 0)

//    nb.rotation = SCNVector4(x: 0, y: 0, z: 1, w: CGFloat.pi * 0.5)

    let r1 = SCNMatrix4MakeRotation(.pi * -0.125, 1, 0, 0)
    let r2 = SCNMatrix4MakeRotation(.pi * 0.5, 0, 0, 1)

    nb.transform =  SCNMatrix4Mult(SCNMatrix4Mult( r1 , r2 ), nb.transform)

//    nb.eulerAngles = SCNVector3(x : .pi * -0.25, y: 0, z: CGFloat.pi * 0.5)

//    nb.simdLocalRotate(by: simd_quatf.init(angle: .pi * 0.5, axis: SIMD3<Float>(x: 1, y: 0, z: 0)))
//    nb.localRotate(by: SCNQuaternion(x: 1, y: 0, z: 0, w: .pi * 0.25))
//    nb.rotate(by: SCNQuaternion.init(x: 0, y: 1, z: 0, w: CGFloat.pi * 1), aroundTarget: SCNVector3(x: 0, y: 0, z: -2))

//    let rr = SCNQuaternion(x: 0.2, y: 0.3, z: 0.5, w: 1)
//    nb.rotate(by: rr, aroundTarget: SCNVector3(x: 0, y: 0, z: 0))

    nb.pivot = SCNMatrix4MakeTranslation(0, -2, -0)


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
//    let nba = SCNAction.rotateBy(x: 0, y: 0.5 * CGFloat.pi, z: 0, duration: 4)

    let nba = SCNAction.rotateBy(x: 0.5 * CGFloat.pi, y: 0, z: 0, duration: 2)
    let nbb = nba.reversed() //  SCNAction.rotateBy(x: 0, y: -0.5 * CGFloat.pi, z: 0, duration: 2)
    let nbc = SCNAction.sequence([nba, nbb])

    //    nb.runAction(nba)
    nb.runAction(SCNAction.repeatForever(nbc))

  }
}
