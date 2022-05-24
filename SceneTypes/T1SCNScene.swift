// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit
import RealityKit

func now() -> Double {
  return Double ( DispatchTime.now().uptimeNanoseconds / 1000 ) / 1000000.0
}

struct Times {
  var currentTime : Double = now()
  var lastTime : Double = now()
  var startTime : Double = now()
}

class T1SCNScene : SCNScene, SCNSceneRendererDelegate {
  var group : String { get { "abstract base class" } }
  var myCameraNode : SCNNode
  var size : CGSize = .zero
  var scale : CGFloat = 0

  class Options {
    var height : Int = 1
    var width : Int = 1
    var depth : Int = 1
  }

  var options = Options()

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


  func reset() {
    self.rootNode.childNodes.dropFirst().forEach { $0.removeFromParentNode() }
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

  var zoom : CGFloat = 1
  var dist : CGFloat = 0

  func zoom(_ n : CGFloat) {
    //    print("zoomed \(n)")
    zoom = n

    if self.rootNode.childNodes.count < 2 {
      // FIXME: don't know why this fails -- works on Simple4 -- fails on Simple6
      print("zoom failed")
    } else {
      self.rootNode.childNodes[1].position.z = XFloat(min(999, max(0.1, dist / max(n, 0.1))))
    }
    //    print("\(self.rootNode.childNodes[1].position.z)")
  }

  func updateZoom(_ n : CGFloat) {
    dist /= max(n, 0.1)
    dist = min(dist, 999)
    dist = max(dist, 0.01)
  }

  func draw() {
    // implemented by subclasses
  }

}

class PointScene : T1SCNScene {

  func geometry(_ tim : CGFloat) -> SCNGeometry { fatalError("must be overriden by subclass") }
  var pointNode : SCNNode?

  required init() {
    super.init()
  }

  override func draw() {
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

    self.background.contents = XColor.orange

    self.isPaused = false
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
