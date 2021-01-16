// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import Accelerate

class Vogel_Disk : PointScene {

  override var group : String { get  { "Point Clouds" } }

  required init() {
    super.init()
    let z = SCNVector3(0, 0, 1)
    let j = SCNAction.rotate(by: CGFloat.pi * 2, around: z, duration: 10)
    let act = SCNAction.repeatForever(j)
    self.pointNode!.runAction(act)

  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func geometry(_ tim : CGFloat) -> SCNGeometry {
    let cnt : Int = 128
    let rotationSpeed : Float = 0.2

    let tau = Float.pi * 2
    let goldenRatio : Float = (sqrt(5) + 1) / 2


    func rot2d(_ t : Float) -> simd_float2x2 {
      let c = cos(t)
      let s = sin(t)
      return simd_float2x2( SIMD2<Float>(c, s), SIMD2<Float>(-s, c) );
    }


    let vertices : [SCNVector3] = (0..<cnt).map { iid in
      let t = sqrt( Float(iid) / Float(cnt) )
      let r = tau * (1 - 1 / goldenRatio) * Float(iid) + Float(tim) * rotationSpeed

      let p = SIMD2<Float>(t, 0) * rot2d(r)
      return SCNVector3( p.x * 35 ,  p.y * 35  , 0.2)


    }

    let vertexSource = SCNGeometrySource(vertices: vertices)

    let pointCloudElement = SCNGeometryElement.init(indices: Array(Int32(0)..<Int32(cnt) ), primitiveType: .point)
    pointCloudElement.pointSize = 0.3
    pointCloudElement.minimumPointScreenSpaceRadius = 5
    pointCloudElement.maximumPointScreenSpaceRadius = 50
    let geometry = SCNGeometry(sources: [vertexSource], elements: [pointCloudElement])

    let material = SCNMaterial()
    material.diffuse.contents = NSColor.green
    geometry.firstMaterial = material

    return geometry
  }

}
