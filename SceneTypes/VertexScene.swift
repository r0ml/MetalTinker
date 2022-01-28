// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit

class VertexNode : SCNNode {

  static func make(_ s : String, _ l : String, _ pp : String, _ n : Int) -> SCNNode {

//    super.init()
    
    let p = SCNProgram()

    p.fragmentFunctionName = String("\(s)___\(pp)___Fragment")
    //     p.vertexFunctionName = "flatVertexFn"
    p.vertexFunctionName = String("\(s)___\(pp)___Vertex")

    p.library = metalLibraries.first(where: {$0.label == l })!

    let planeSize = CGSize(width: 16, height: 9)
    var ttt = Times()


//    config.justInitialization()

    // FIXME:
    // I could also use key-value coding on an nsdata object
    // on geometry or material call  setValue: forKey: "uni"

    // Bind the name of the fragment function parameters to the program.
    p.handleBinding(ofBufferNamed: "uni",
                    frequency: .perFrame,
                    handler: {
                      (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
                      //                           let s = renderer.currentViewport.size

                      let s = planeSize
                      ttt.currentTime = now()

                      var u = setupUniform(size: CGSize(width: s.width * 10.0, height: s.height * 10), times: ttt)
                      buffer.writeBytes(&u, count: MemoryLayout<Uniform>.stride)

                    })

/*    p.handleBinding(ofBufferNamed: "in",
     frequency: .perFrame,
     handler: {
     (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
     if let ib = self.config.initializationBuffer {
     buffer.writeBytes(ib.contents(), count: ib.length)
     } else {
     var zero = 0
     buffer.writeBytes(&zero, count: MemoryLayout<Double>.stride)
     }
     })
*/


    let j = SCNMaterial()
    j.program = p
    j.isDoubleSided = true

    let im = XImage.init(named: "london")!
    let matprop = SCNMaterialProperty.init(contents: im)
    j.setValue(matprop, forKey: "tex")

    j.setValue(Float(0.05), forKey: "thickness")
    j.setValue(Float(0.3), forKey: "radius")
//    var arcid : Int32 = 0
      // let zz : [Float] = [Float(0.5 + 0.2 * (iid == 1 ? 1 : 0)), Float(0.5), Float(0.5 + 0.2 * (iid == 2 ? 1 : 0)), Float(1)]
    j.setValue(Int32(0), forKey: "arcid")

//    j.setValue(config.initializationBuffer, forKey: "in")

//    let gs = SCNGeometrySource.init(buffer: <#T##MTLBuffer#>, vertexFormat: <#T##MTLVertexFormat#>, semantic: <#T##SCNGeometrySource.Semantic#>, vertexCount: <#T##Int#>, dataOffset: <#T##Int#>, dataStride: <#T##Int#>)
//    let gs = SCNGeometrySource.init(data: <#T##Data#>, semantic: <#T##SCNGeometrySource.Semantic#>, vectorCount: <#T##Int#>, usesFloatComponents: <#T##Bool#>, componentsPerVector: <#T##Int#>, bytesPerComponent: <#T##Int#>, dataOffset: <#T##Int#>, dataStride: <#T##Int#>)

// n is number of triangles
    let gs = SCNGeometrySource.init(vertices: (0..<n).flatMap { (q : Int) -> [SCNVector3] in [SCNVector3(0, 0, 0), SCNVector3(0, 1, 0), SCNVector3(1, 1, 0) ] } )
      // Array.init(repeating: SCNVector3Zero, count: 3 * n))
    let ge = SCNGeometryElement.init(indices: (0..<n).flatMap { (q : Int) -> [Int32] in [Int32(3*q), Int32(3*q+1), Int32(3*q+2)] }, primitiveType: .triangles)

    let k = SCNGeometry.init(sources: [gs], elements: [ge])

    // Why does the size not matter here???
//    let g = SCNPlane(width: planeSize.width, height: planeSize.height)
    k.materials = [j]

    let gn = SCNNode(geometry: k)
    gn.name = "Shader plane node"

    let gn2 : SCNNode = gn.clone()
    gn2.geometry = gn.geometry?.copy() as! SCNGeometry?
    let j2 = j.copy() as! SCNMaterial
    j2.setValue(Int32(1), forKey: "arcid")
    gn2.geometry?.firstMaterial = j2

    let gn3 : SCNNode = gn.clone()
    gn3.geometry = gn.geometry?.copy() as! SCNGeometry?
    let j3 = j.copy() as! SCNMaterial
    j3.setValue(Int32(2), forKey: "arcid")
    gn3.geometry?.firstMaterial = j3


    let gnx = SCNNode()
    gnx.addChildNode(gn)
    gnx.addChildNode(gn2)
        gnx.addChildNode(gn3)
    return gnx
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  static func setupUniform( size: CGSize /* , scale : Int, */ /* uniform uni: MTLBuffer */ , times : Times ) -> Uniform {

    var uniform = Uniform()

//    iFrame += 1

    #if os(macOS)
    let modifierFlags = XEvent.modifierFlags
    let mouseButtons = XEvent.pressedMouseButtons
    #endif

    //   let mouseButtons = NSEvent.pressedMouseButtons

    // let w = Float(size.width)
    // let h = Float(size.height)
    // let s = Float(scale)

    // ==================================================
    // These are zapped out
    // not sure in SceneKit how to map the location of a touch onto the Node which is being rendered here.
    uniform.iMouse    = SIMD2<Float>(repeating: 0.5) //       SIMD2<Float>( s * Float(mouseLoc.x)  / w, 1 - s * Float(mouseLoc.y) / h )
    uniform.lastTouch = SIMD2<Float>(repeating: 0.5) //       SIMD2<Float>( s * Float(lastTouch.x) / w, 1 - s * Float(lastTouch.y) / h );

/*    if let hl = touchLoc, let ohl = startDragLoc {
      uniform.iMouse = SIMD2<Float>(x: Float(hl.x), y: Float(hl.y) )
      uniform.lastTouch = SIMD2<Float>(x: Float(ohl.x), y: Float(ohl.y) )
    }
 */
    #if os(macOS)
    uniform.mouseButtons = Int32(mouseButtons)
    uniform.eventModifiers = Int32(modifierFlags.rawValue)
    #endif
    
    // ==================================================

    // ==================================================
    // for now, this too is zpped out until I figure out how to deal with keyPresses
    // Pass the key event in to the shader, then reset (so it only gets passed once)
    // when the key is released, event handling will so indicate.
    uniform.keyPress = SIMD2<UInt32>(repeating: 0) // self.keyPress
    // self.keyPress.x = 0;
    // ==================================================

    // set resolution and time
//    uniform.iFrame = Int32(iFrame)
    uniform.iResolution = SIMD2<Float>(Float(size.width), Float(size.height)) * 10
    uniform.iTime = Float(times.currentTime - times.startTime)
    uniform.iTimeDelta = Float(times.currentTime - times.lastTime)

    // Set up iDate
    let _date = Date()
    let components = Calendar.current.dateComponents( Set<Calendar.Component>([.year, .month, .day, .hour, .minute,  .second]), from:_date)
    let d = components.second! + components.minute! * 60 + components.hour! * 3600;
    let d2 = Float(d) + Float(_date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1));
    if let y = components.year, let m = components.month, let d = components.day {
      uniform.iDate = SIMD4<Float>(Float(y), Float(m), Float(d), d2)
    }

    // Done.  Sync with GPU
    //    uni.didModifyRange(0..<uni.length)
    return uniform
  }



}


// Renders a spritekit as the background for a SceneKit.  Hence, this is the same as just displaying the SpriteKit
class VertexSCNScene : T3SCNScene {
  override var group : String { get { "Vertices" } }
  
//  override var group : String { get { self.library } }
//  var shader : String
//  var library : String
//  var config : ConfigController
//  var touchLoc : CGPoint?
//  var startDragLoc : CGPoint?

  required init() {
 //   self.shader = shader
//    self.library = library
//    self.config = ConfigController(shader)

    super.init()

//    config.justInitialization()

    // FIXME:
    // I could also use key-value coding on an nsdata object
    // on geometry or material call  setValue: forKey: "uni"

    let vx = VertexNode.make("Arcs", "Point Clouds", "", 50) // I want 3 of these?
    vx.position = SCNVector3(0.5, 0.5, 0.5)
    self.rootNode.addChildNode(vx)

    self.background.contents = XColor.orange

    self.isPaused = false



  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  var iFrame : Int = 0

  func setupUniform( size: CGSize /* , scale : Int, */ /* uniform uni: MTLBuffer */ , times : Times ) -> Uniform {

    var uniform = Uniform()

    iFrame += 1

    #if os(macOS)
    let modifierFlags = XEvent.modifierFlags
    let mouseButtons = XEvent.pressedMouseButtons
    #endif

    //   let mouseButtons = NSEvent.pressedMouseButtons

    // let w = Float(size.width)
    // let h = Float(size.height)
    // let s = Float(scale)

    // ==================================================
    // These are zapped out
    // not sure in SceneKit how to map the location of a touch onto the Node which is being rendered here.
    uniform.iMouse    = SIMD2<Float>(repeating: 0.5) //       SIMD2<Float>( s * Float(mouseLoc.x)  / w, 1 - s * Float(mouseLoc.y) / h )
    uniform.lastTouch = SIMD2<Float>(repeating: 0.5) //       SIMD2<Float>( s * Float(lastTouch.x) / w, 1 - s * Float(lastTouch.y) / h );

/*    if let hl = touchLoc, let ohl = startDragLoc {
      uniform.iMouse = SIMD2<Float>(x: Float(hl.x), y: Float(hl.y) )
      uniform.lastTouch = SIMD2<Float>(x: Float(ohl.x), y: Float(ohl.y) )
    }
 */
    #if os(macOS)
    uniform.mouseButtons = Int32(mouseButtons)
    uniform.eventModifiers = Int32(modifierFlags.rawValue)
    #endif

    
    // ==================================================

    // ==================================================
    // for now, this too is zpped out until I figure out how to deal with keyPresses
    // Pass the key event in to the shader, then reset (so it only gets passed once)
    // when the key is released, event handling will so indicate.
    uniform.keyPress = SIMD2<UInt32>(repeating: 0) // self.keyPress
    // self.keyPress.x = 0;
    // ==================================================

    // set resolution and time
    uniform.iFrame = Int32(iFrame)
    uniform.iResolution = SIMD2<Float>(Float(size.width), Float(size.height)) * 10
    uniform.iTime = Float(times.currentTime - times.startTime)
    uniform.iTimeDelta = Float(times.currentTime - times.lastTime)

    // Set up iDate
    let _date = Date()
    let components = Calendar.current.dateComponents( Set<Calendar.Component>([.year, .month, .day, .hour, .minute,  .second]), from:_date)
    let d = components.second! + components.minute! * 60 + components.hour! * 3600;
    let d2 = Float(d) + Float(_date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1));
    if let y = components.year, let m = components.month, let d = components.day {
      uniform.iDate = SIMD4<Float>(Float(y), Float(m), Float(d), d2)
    }

    // Done.  Sync with GPU
    //    uni.didModifyRange(0..<uni.length)
    return uniform
  }

  /*

   func convertToScenOf(point: CGPoint, bounds: CGRect) -> SCNVector3{

   // assuming that the fieldOfView is vertical

   let ss = NSScreen.main?.frame.size ?? CGSize(width: 16, height: 9)
   //    print(ss)
   let mp = point - bounds.size / 2.0
   var y = tan(myCameraNode.camera!.fieldOfView / 180 / 2 * CGFloat.pi) * myCameraNode.position.z
   var x = y * ss.width / ss.height

   let adjb = CGSize(width: bounds.size.height * ss.width / ss.height, height: bounds.size.height)
   //    print(adjb)

   if myCameraNode.camera!.projectionDirection == .vertical {

   } else {
   let z = x
   x = y
   y = z
   }

   let xx = mp.x * x * 2 / adjb.width
   let yy = mp.y * y * 2 / adjb.height


   let d = rootNode.childNodes[0].position.z

   let target = SCNVector3(x: xx, y: yy, z: d - 0.01 )
   return target
   /*
   let Z_Far:CGFloat = 0.1
   var Screen_Aspect : CGFloat = 0; // 0.3; // UIScreen.main.bounds.size.width > 400 ? 0.3 : 0.0
   // Calculate the distance from the edge of the screen
   let Y = tan(myCamera.fieldOfView/180/2 * CGFloat.pi) * Z_Far-Screen_Aspect
   let X = tan(myCamera.fieldOfView/2/180 * CGFloat.pi) * Z_Far-Screen_Aspect * bounds.size.width/bounds.size.height
   let alphaX = 2 *  CGFloat(X) / bounds.size.width
   let alphaY = 2 *  CGFloat(Y) / bounds.size.height
   let x = -CGFloat(X) + point.x * alphaX
   let y = CGFloat(Y) - point.y * alphaY
   let target = SCNVector3Make(x, y, -Z_Far)
   return target
   //    return myCameraNode.convertPosition(target, to: rootNode)
   */
   }

   func hiTest(point : CGPoint, bounds : CGRect) -> CGPoint? {
   let a = convertToScenOf(point: point, bounds: CGRect(origin: .zero, size: bounds.size))
   let b = myCameraNode.position
   var hto = [String: Any]()
   hto[SCNHitTestOption.searchMode.rawValue] = SCNHitTestSearchMode.all.rawValue
   let k = self.rootNode.hitTestWithSegment(from: b, to: a, options: hto)

   //   print(k)
   let res = k.first?.textureCoordinates(withMappingChannel: 0)
   return res
   // return k.first
   }
   */
}
