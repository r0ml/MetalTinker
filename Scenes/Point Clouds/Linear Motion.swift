
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import Accelerate

class Linear_Motion : PointScene {
  override var group : String { get  { "Point Clouds" } }

  required init() {
    super.init()
  }

  override func draw() {
    #if os(macOS)
    self.background.contents = XColor.init(deviceWhite: 112 / 255.0, alpha: 1)
    #else
    self.background.contents = XColor.init(white: 112 / 255.0, alpha: 1)
    #endif

    let act = SCNAction.repeatForever(SCNAction.customAction(duration: Double.pi) { (n, t) in
      n.geometry = self.geometry(t)
    }
    )
    
    self.pointNode!.runAction(act)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let motionBlur = 3
  let dotcount = 16

  override func geometry(_ tim : CGFloat) -> SCNGeometry {
    func rot2d(_ t : Float) -> simd_float2x2 {
      let c = cos(t)
      let s = sin(t)
      return simd_float2x2( SIMD2<Float>(c, s), SIMD2<Float>(-s, c) );
    }

    let vertices : [SCNVector3] =

    (0 ..< dotcount * motionBlur).map { iid in
    let p = dot_pos( iid, Float(tim) ) // , Float(iid) )
      return SCNVector3( p.x * 70 ,  p.y * 70  , 0.2)
  }

    let vertexSource = SCNGeometrySource(vertices: vertices)

    let colors : [SIMD4<Float>] = (0..<dotcount * motionBlur).map { n in dot_color( n ) }

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



    let pointCloudElement = SCNGeometryElement.init(indices: Array( Int16(0)..<Int16(dotcount * motionBlur) ),
                                               primitiveType: .point)
    pointCloudElement.pointSize = 1
    pointCloudElement.minimumPointScreenSpaceRadius = 5
    pointCloudElement.maximumPointScreenSpaceRadius = 50
    let geometry = SCNGeometry(sources: [vertexSource, colorSource ],
                               elements: [pointCloudElement])

    return geometry
  }

  func dot_pos(_ iid : Int, _ tim : Float)  -> SIMD2<Float> {
    let tau = Float.pi * 2
    let t = tim * 2
      let angle = -tau * Float(iid / motionBlur) / Float(dotcount)
    let jj = (iid % motionBlur)
    let z = sin( fmod(t, tau) - Float(jj) * 0.03 - angle*1.5)
    let m  = (z*z  / 1.4 + 0.2)
    let k = SIMD2<Float>(angle, angle) - SIMD2<Float>(0, 33)
    let j = SIMD2<Float>(m, m) * SIMD2<Float>(cos(k.x), cos(k.y))
    return j * 0.7
  }

  func dot_color(_  an : Int) -> SIMD4<Float> {
    let mm = (an % motionBlur) // number of motion blurs
    let anx = Float(an / motionBlur) / Float(dotcount)
    let a=(1 - anx)*6
    return clamp( SIMD4<Float>(abs(a-3)-1, 2-abs(a-2), 2-abs(a-4), 1 - Float(mm) * 0.4),   min: 0, max: 1);
  }
}
