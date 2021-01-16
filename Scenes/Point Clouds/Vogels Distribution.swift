// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import Accelerate

class Vogels_Distribution : PointScene {
  override var group : String { get  { "Point Clouds" } }

  override func geometry(_ tim : CGFloat) -> SCNGeometry {
    let cnt : Int = 2000
    let tau = Float.pi * 2
    let goldenRatio : Float = (sqrt(5) + 1) / 2
    func rot2d(_ t : Float) -> simd_float2x2 {
      let c = cos(t)
      let s = sin(t)
      return simd_float2x2( SIMD2<Float>(c, s), SIMD2<Float>(-s, c) );
    }


    let vertices : [SCNVector3] = (0..<cnt).map { iid in
      let t = sqrt( Float(iid) / (Float(cnt) / 2.2) )
      let r = tau * (1 - 1 / goldenRatio)
      let p = SIMD2<Float>(t, 0) * rot2d(r * Float(iid))
      return SCNVector3( p.x * 70 ,  p.y * 70  , 0.2)
    }

    let vertexSource = SCNGeometrySource(vertices: vertices)

    let pointCloudElement = SCNGeometryElement.init(indices: Array(Int32(0)..<Int32(cnt)), primitiveType: .point)
    pointCloudElement.pointSize = 1
    pointCloudElement.minimumPointScreenSpaceRadius = 5
    pointCloudElement.maximumPointScreenSpaceRadius = 50
    let geometry = SCNGeometry(sources: [vertexSource], elements: [pointCloudElement])

    let material = SCNMaterial()
    material.diffuse.contents = NSColor.green
    geometry.firstMaterial = material

    return geometry
  }

}
