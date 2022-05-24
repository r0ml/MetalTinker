// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import Accelerate



class Dot_Line : PointScene {
  var time : TimeInterval = 0

  override var group : String { get  { "Circles - Scene" } }

  let velocity = 6
  let dotCount = 32
  let FREQUENCY = CGFloat(2.5)
  let AMPLITUDE = 0.08
  let RADIUS = 0.9


  required init() {
    super.init()
  }

  override func draw() {
    #if os(macOS)
    self.background.contents = XColor.init(deviceWhite: 112 / 255.0, alpha: 1)
    #else
    self.background.contents = XColor.init(white: 112 / 255.0, alpha: 1)
    #endif

    let act = SCNAction.repeatForever( SCNAction.customAction(duration: 2.0 * Double(velocity) * Double.pi) { (n, t) in
      n.geometry = self.geometry(t)
    }
    )

    self.pointNode!.runAction(act)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

/*
   initialize() {
     in.clearColor = {1, 1, 1, 1};
     in.pipeline._1 = {0, 1, REPEAT, 0};
   }

   vertexPointPass(_1) {
     VertexOutPoint v;


     float phase = float(iid) * TAU / in.pipeline._1.z;
     float offsetValue = sin(uni.iTime * FREQUENCY + phase);

     float2 pos = float2( 2 * float(iid) / REPEAT - 1,  2 * AMPLITUDE * offsetValue);
     float radius = (offsetValue + 1.1) * RADIUS;
     radius *= uni.iResolution.y / (1.1 * REPEAT);

     v.point_size = radius;
     v.color = {0, 0, 0, 1};
     v.where.xy = pos;
     v.where.zw = {0, 1};
     return v;
   }   */

  override func geometry(_ tim : CGFloat) -> SCNGeometry {

    let vertices : [SCNVector3] = (0..<dotCount).map { iid in
      let tau = CGFloat.pi * 2
      let phase = CGFloat(iid) * tau / CGFloat(dotCount)
      let offsetValue : Float = sin(Float(tim) * Float(FREQUENCY) + Float(phase))

      let pos = SIMD2<Float>(2 * Float(iid) / Float(dotCount) - 1, 2 * Float(AMPLITUDE) * offsetValue)
      let radius = (offsetValue + 1.1) * Float(RADIUS) * 100 / (1.1 * Float(dotCount))

      return SCNVector3( pos.x * 70,  pos.y * 50  , 0.2)
    }

    let vertexSource = SCNGeometrySource(vertices: vertices)

/*    let colors : [SIMD4<Float>] = (0..<cnt).map { (iid)  -> SIMD4<Float> in
      let s3 = SIMD3<Float>(Float(sin(t)) + Float(0.2), Float(0.4) * Float(cos(t+2.0)) + Float(0.2), Float(0.5) * Float(cos( CGFloat(velocity) * t + 2.0))+0.4)
      return SIMD4<Float>( Float(vertices[iid].y / 50) * s3.x, Float(vertices[iid].x / 70) * s3.y , 0, 1)
    }
*/
    /*
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
*/


//    let indices : [UInt8] = Array(0..<8)
    let pces = (0..<dotCount).map { iid -> SCNGeometryElement in
      let tau = CGFloat.pi * 2
      let phase = CGFloat(iid) * tau / CGFloat(dotCount)
      let offsetValue : Float = sin(Float(tim) * Float(FREQUENCY) + Float(phase))
      let radius = (offsetValue + 1.1) * Float(RADIUS) * 100 / (1.1 * Float(dotCount))


      let pointCloudElement = SCNGeometryElement.init(indices: [Int32(iid)], primitiveType: .point)
      pointCloudElement.pointSize = CGFloat(radius)
      pointCloudElement.minimumPointScreenSpaceRadius = CGFloat(5 * radius)
      pointCloudElement.maximumPointScreenSpaceRadius = CGFloat(15 * radius)
      return pointCloudElement
    }

    let geometry = SCNGeometry(sources: [vertexSource /*, colorSource */], elements: pces)

//    let material = SCNMaterial()
//    material.diffuse.contents = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
//    geometry.firstMaterial = material

    return geometry
  }


//  override func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//    super.renderer(renderer, updateAtTime: time)
//    self.time = time
//    let z = SCNQuaternion(x: 0, y: 0, z: -0.1/60, w: 1)
//    self.rootNode.childNodes[0].localRotate(by: z)
//    self.rootNode.childNodes[0].geometry = self.geometry(CGFloat(time))
//  }
}
