// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml




import SceneKit
import SpriteKit

protocol TinkerScene {
  var group : String {get}
}

var scenery : Dictionary<String, Dictionary<String, T1SCNScene>> = {
  var a = Dictionary<String, Dictionary<String, T1SCNScene>>()

  let j = getSubclassesOf(T1SCNScene.self).filter { ($0 as? T3ShaderSCNScene.Type) == nil }

  // FIXME: this is broken -- need to split out the "SceneKit" shaders
  let m = ShaderTwo.function.libs.filter({ $0.label != "default"  }).sorted { $0.label!.lowercased() < $1.label!.lowercased() }
  // m are the libraries

  for lib in m {
    let res = lib.functionNames.compactMap { (nam) -> String? in
      var pnam : String
      if nam.hasSuffix("______Fragment") {
        pnam = String(nam.dropLast(14))
      } else {
        return nil
      }
      return pnam
    }
    let ll = lib.label!
    for ss in res {
      var b = a[ ll, default: Dictionary<String, T1SCNScene>()]
      b[ ss ] = T3ShaderSCNScene(shader: ss, library: ll)
      a[ ll ] = b
    }
  }

  let k = j.compactMap { (cc : T1SCNScene.Type) -> T1SCNScene? in if cc == PointScene.self { return nil } else { return cc.init() } }


  for kk in k {
    var n = kk.group
    if n == "abstract base class" { continue }
    var b = a[ n, default: Dictionary<String, T3SCNScene>() ]
    b[ String(describing: type(of: kk) ) ] = kk
    a[n] = b
  }
  
//
//  a["Simple"] = register( [Simple(), Simple2(), Simple4() ] )
//
//  a["3d scene"] = register( [] )
//  a["Shapes3d"] = register( [] )
//  a["Spheres"] = register( [] )

  return a
}()

// ==========================================================================
/*
func register(_ dd : [SCNScene]) -> Dictionary<String, SCNScene> { // _ d : inout Dictionary<String, SceneProtocol>) {
  var b = Dictionary<String, SCNScene>()
  dd.forEach { d in
    let a = String(describing: type(of: d))
    b[a] = d
  }
  return b
}

func getAllClasses() -> [AnyClass] {
  var count : UInt32 = 0
  if let classList = objc_copyClassList(&count) {
    return UnsafeBufferPointer(start: classList, count: Int(count)).filter { class_getInstanceSize($0) > 0 && class_getSuperclass($0) != nil }
  }
  return []
}

// FIXME: HERE BE DRAGONS
func getSubclassesOf3<T>(_ c : T.Type) -> [T.Type] where T : Any {
  let a = getAllClasses()
  var res = [T.Type]()
  for j in a {
    if let k = j as? T.Type {
      res.append(k)
    }
  }
  return res
//  return (getAllClasses().filter { ($0 as? T.Type) != nil } as? [T.Type]) ?? []
}
*/

func getSubclassesOf<T>(_ c : T.Type) -> [T.Type] where T : AnyObject {
  var count : UInt32  = 0
  var res : [T.Type] = []
  let cn = String(cString: class_getName(c))
  if let classList = objc_copyClassList(&count) {
    let cl = UnsafeBufferPointer(start: classList, count: Int(count))
    for var n : AnyClass in cl {
      let no : AnyClass = n
      while let s = class_getSuperclass(n) {
        if String(cString: class_getName(s)) == cn,
          let nn = no as? T.Type {
          res.append(nn)
          break
        } else {
          n = s
        }
      }
    }
  }
  return res
}

// In order to handle interaction, I need to subclass SKScene
// (for things like didMove()?  and definitely  touchesBegan

class SpriteTest : SKScene {

  override required init() {
    let size = CGSize(width: 1400, height: 1000)
    super.init(size: size)
    self.scaleMode = .aspectFit

    self.backgroundColor = SKColor.purple

    let a = SKShapeNode(circleOfRadius: size.height / 3.0)
    a.strokeColor = SKColor.yellow
    a.fillColor = SKColor.green
    a.lineWidth = 0.8
    a.glowWidth = 0

    a.position = CGPoint(x: size.width/2.0, y: size.height/2.0)

    //    a.position = CGPoint(x: size.width / 2, y: 400)
    a.physicsBody?.isDynamic = false

    self.addChild(a)

    let b = SKLabelNode(text: "hello, this is SpriteKit")
    b.horizontalAlignmentMode = .left
    b.position = CGPoint(x: 100, y: 100)
    self.addChild(b)

    // *** I NEED THIS FOR UPDATE ***
    //    self.isPaused = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func update( _ ti : TimeInterval) {
    //    print("update \(ti)")
  }

}


extension SKColor {
  func toSRGB() -> SKColor {

    #if os(macOS)
    let a = self.redComponent
    let b = self.greenComponent
    let c = self.blueComponent
    let d = self.alphaComponent
#else
    var a : CGFloat = 0
    var b : CGFloat = 0
    var c : CGFloat = 0
    var d : CGFloat = 0
    self.getRed(&a, green: &b, blue: &c, alpha: &d)
    #endif

    let r = a < 0.0031308 ? 12.92 * a : 1.055 * pow(a, 1/2.2) - 0.055
    let g = b < 0.0031308 ? 12.92 * b : 1.055 * pow(b, 1/2.2) - 0.055
    let bl = c < 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1/2.2) - 0.055

    #if os(macOS)
    return SKColor.init(calibratedRed: r, green: g-0.03, blue: bl-0.02, alpha: d)
    #else
    return SKColor.init(red: r, green: g-0.03, blue: bl-0.03, alpha: d)
    #endif

  }
}

