// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit

class T1SCNScene : SCNScene, SCNSceneRendererDelegate, TinkerScene {
  var group : String { get { "abstract base class" } }
  var myCameraNode : SCNNode
  var size : CGSize = .zero
  var scale : CGFloat = 0

  override required init() {
    let c = SCNCamera()
    c.usesOrthographicProjection = false
    c.zNear = 0
    c.zFar = 1677 // this seems to be the maximum value:  1678 doesn't work

    myCameraNode = SCNNode()
    myCameraNode.camera = c
    myCameraNode.name = "Camera node"
    super.init()
    self.rootNode.addChildNode(myCameraNode)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var showsStatistics : Bool = true
  var debugOptions: SCNDebugOptions = []

  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    renderer.showsStatistics = self.showsStatistics
    renderer.debugOptions = self.debugOptions
  }

  func setSize(_ sz : CGSize) {
    // I could either 1) scale the size to have one co-ordinate always be 100 -- or
    // 2) use the size in generating the geometry
    let k : CGFloat = min(sz.width, sz.height)
    self.scale = k / 10.0
    self.size = CGSize(width: sz.width / scale, height: sz.height / scale)

    let cd = tan(myCameraNode.camera!.fieldOfView * CGFloat.pi / 180.0) * (myCameraNode.camera!.projectionDirection == .vertical ? size.height : size.width) / 2.0
    myCameraNode.position = SCNVector3(0, 0, cd)
  }

  func pause(_ t : Bool) {
    self.isPaused = t
  }
}

class PointScene : T1SCNScene {

  func geometry(_ tim : CGFloat) -> SCNGeometry { fatalError("must be overriden by subclass") }
  var pointNode : SCNNode?

  required init() {
    super.init()


    let g = self.geometry(0)
    let gn = SCNNode(geometry: g)
    gn.name = "Shader plane node"
    gn.position = SCNVector3(0, 0, 0.5)

    // I could set the background to a CAMetalLayer and then render into it.....

    let target = SCNLookAtConstraint(target: gn)
    target.isGimbalLockEnabled = true
    myCameraNode.constraints = [target]

    pointNode = gn
    self.rootNode.addChildNode(pointNode!)

    self.background.contents = NSColor.orange

    self.isPaused = false
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
