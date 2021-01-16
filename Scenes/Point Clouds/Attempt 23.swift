// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import Accelerate

class Attempt_23 : PointScene {
  var time : TimeInterval = 0

  override var group : String { get  { "Point Clouds" } }

  let velocity = 6

  required init() {
    super.init()
    self.background.contents = NSColor.init(deviceWhite: 112 / 255.0, alpha: 1)

    let act = SCNAction.repeatForever( SCNAction.customAction(duration: 2.0 * Double(velocity) * Double.pi) { (n, t) in
      n.geometry = self.geometry(t)
    }
    )

    self.pointNode!.runAction(act)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func geometry(_ tim : CGFloat) -> SCNGeometry {
    let x = 33
    let y = 18
    let cnt : Int = x * y

    let vertices : [SCNVector3] = (0..<cnt).map { iid in
      let (yy, xx) = iid.quotientAndRemainder(dividingBy: x)

      let cdx = (Float(xx) / Float(x) * 2 - 1 )
      let cdy = (Float(yy) / Float(y) * 2 - 1 )
      let cdz = sin( Float(tim) + 10 * length(SIMD2<Float>(cdx + 1 + 0.5 * sin(Float(tim)), cdy + 1 + 0.5 * sin(Float(tim)))))
      return SCNVector3( cdx * 70 ,  cdy * 50  , cdz * 3)
    }

    let vertexSource = SCNGeometrySource(vertices: vertices)
    let t = tim / CGFloat(velocity)

    let colors : [SIMD4<Float>] = (0..<cnt).map { (iid)  -> SIMD4<Float> in
      let s3 = SIMD3<Float>(Float(sin(t)) + Float(0.2), Float(0.4) * Float(cos(t+2.0)) + Float(0.2), Float(0.5) * Float(cos( CGFloat(velocity) * t + 2.0))+0.4)
      return SIMD4<Float>( Float(vertices[iid].y / 50) * s3.x, Float(vertices[iid].x / 70) * s3.y , 0, 1)
    }

    let colorSource = colors.withUnsafeBufferPointer { n -> SCNGeometrySource in
      let colorData = Data( buffer: n)
      return SCNGeometrySource(data: colorData,
                                        semantic: .color,
                                        vectorCount: colors.count,
                                        usesFloatComponents: true,
                                        componentsPerVector: 4,
                                        bytesPerComponent: 4,
                                        dataOffset: 0,
                                        dataStride: 16)
    }

    let pointCloudElement = SCNGeometryElement.init(indices: Array(Int32(0)..<Int32(cnt) ),
                                               primitiveType: .point)
    pointCloudElement.pointSize = 0.6
    pointCloudElement.minimumPointScreenSpaceRadius = 5
    pointCloudElement.maximumPointScreenSpaceRadius = 50
    let geometry = SCNGeometry(sources: [vertexSource, colorSource],
                               elements: [pointCloudElement])

    return geometry
  }
}
