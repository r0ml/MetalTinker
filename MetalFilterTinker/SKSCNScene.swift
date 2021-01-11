// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit
import SpriteKit

class SKSCNScene : T3SCNScene {
//  override var group : String { get  { "" } }
  var skScene : SKScene { get { SKScene() } }

  required init() {

    super.init()

    let j = SCNMaterial( )

    let st = skScene
    j.isDoubleSided = true

    j.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
    j.diffuse.contents = st

    let c = SCNCamera()
    c.usesOrthographicProjection = false
    c.zNear = 0
    c.zFar = 1000

    let cn = SCNNode()
    cn.camera = c
    cn.name = "Camera node"

    // why does this not work if I double the width and height?
    let planeSize = CGSize(width: 700, height: 500)

    let cd = tan(c.fieldOfView * CGFloat.pi / 180.0) * (c.projectionDirection == .vertical ? planeSize.height : planeSize.width) / 2.0
    cn.position = SCNVector3(0, 0, cd)


    let g = SCNPlane(width: planeSize.width, height: planeSize.height)
    g.materials = [j]


    let gn = SCNNode(geometry: g)
    gn.name = "Shader plane node"

    let target = SCNLookAtConstraint(target: gn)
    target.isGimbalLockEnabled = true
    cn.constraints = [target]

    self.dist = cd

    self.rootNode.addChildNode(gn)
    self.rootNode.addChildNode(cn)

    self.background.contents = NSColor.orange

    self.isPaused = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
