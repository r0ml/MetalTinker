// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit
import SpriteKit

class SKSCNScene : T3SCNScene {
//  override var group : String { get  { "" } }
  var skScene : SKScene!
  var planeNode : SCNNode = SCNNode()

  required init() {

    super.init()
    planeNode.name = "Shader plane node"
    self.rootNode.addChildNode(planeNode)
    self.background.contents = XColor.darkGray
  }

  override func setSize(_ sz : CGSize) {
    let osz = self.size
    super.setSize(sz)
    if self.size == osz { return }

    let j = SCNMaterial( )

    let st = skScene
    j.isDoubleSided = true

    j.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
    j.diffuse.contents = st

    j.lightingModel = .constant

    let g = SCNPlane(width: self.size.width, height: self.size.height)
    g.materials = [j]

    planeNode.geometry = g

//    let target = SCNLookAtConstraint(target: gn)
//    target.isGimbalLockEnabled = true
//    myCameraNode.constraints = [target]


//    self.dist = cd


  }

  override func pause(_ t : Bool) {
    super.pause(t)
    skScene.isPaused = t
    planeNode.isPaused = t
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
