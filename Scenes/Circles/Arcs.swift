// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import SpriteKit

class Arcs_Sprite : SKScene {
  let speedx = 1.5
  let strokex = 0.04

  func ring(_ size : CGSize, scale : @escaping (SKNode, CGFloat)->() ) -> SKShapeNode {
    let a = SKShapeNode(circleOfRadius: 0.35 * size.height )
    //    a.fillColor = SKColor.white
    a.glowWidth = 0
    a.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
    a.physicsBody?.isDynamic = false
    a.lineWidth = CGFloat(strokex) * size.height
    a.strokeColor = SKColor(red: 1, green: 0, blue: 231/255.0, alpha: 1).toSRGB()

    let a10 = SKAction.customAction(withDuration: Double.pi * speedx, actionBlock: scale)
    a.run(SKAction.repeatForever(a10))
    return a
  }


  override required init() {
    let size = CGSize(width: 1400, height: 1000)
    super.init(size: size)
    self.scaleMode = .aspectFit

    // let j : CGFloat = 1 / sqrt(5)

    // the background
    self.backgroundColor = // SKColor.init(srgbRed: 0.4, green: 0.6, blue: 1, alpha: 1).usingColorSpace(.extendedSRGB)!
      //      SKColor.init(srgbRed: pow(0.4, j), green: pow( 0.6, j), blue: pow(1, j), alpha: 1)
      SKColor.init(red: 0.84, green: 0.84, blue: 0.84, alpha: 1)


    let aa = SKShapeNode(circleOfRadius: 0.4 * size.height)
    aa.fillColor = SKColor.white
    aa.lineWidth = 0
    aa.position = CGPoint(x: size.width/2.0, y: size.height/2.0)

    self.addChild(aa)

    // the inner blue circle
    let a = SKShapeNode(circleOfRadius: 0.12 * size.height )
    //    a.fillColor = SKColor.white
    a.glowWidth = 0
    a.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
    a.physicsBody?.isDynamic = false
    a.lineWidth = 0
//    a.strokeColor = SKColor(red: 1, green: 0, blue: 231/255.0, alpha: 1).toSRGB()
    a.fillColor = SKColor.init(red: 6/255.0, green: 24/255.0, blue: 245/255.0, alpha: 1)

    let a10 = SKAction.scale(to: 3, duration: 4)
    a10.timingMode = .easeInEaseOut
    let a11 = SKAction.wait(forDuration: 4)
    let a12 = SKAction.scale(to: 1, duration: 4)
    a12.timingMode = .easeInEaseOut
    let a13 = SKAction.wait(forDuration: 4)

    a.run(SKAction.repeatForever(SKAction.sequence([a10, a11, a12, a13])))
    self.addChild(a)

    // the outer ring is in two parts:
    // an underlying black ring
    // an overlayed olive arc which grows and shrinks
    let b = SKShapeNode(circleOfRadius: 0.4 * size.height)
    b.lineWidth = 0.05 * size.height
    b.strokeColor = SKColor.black
    b.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
    self.addChild(b)


    let path = CGMutablePath()
    path.addArc(center: .zero, radius: 0.4 * size.height, startAngle: 0, endAngle: CGFloat.pi, clockwise: true)

    let c = SKShapeNode(path: path)
    c.lineWidth = 0.05 * size.height
    c.strokeColor = SKColor.init(red: 96/255.0, green: 123/255.0, blue: 92/255.0, alpha: 1)
    c.position = CGPoint(x: size.width/2.0, y: size.height/2.0)

    let cc = SKAction.customAction(withDuration: 8) { (n, tx) in
      let path = CGMutablePath()
      path.addArc(center: .zero, radius: 0.4 * size.height, startAngle: CGFloat.pi, endAngle: CGFloat.pi + CGFloat.pi * tx/4, clockwise: false)
      (n as! SKShapeNode).path = path

    }

    let dd = SKAction.customAction(withDuration: 8) { (n, tx) in
      let path = CGMutablePath()
      path.addArc(center: .zero, radius: 0.4 * size.height, startAngle: CGFloat.pi, endAngle: CGFloat.pi + CGFloat.pi * tx/4, clockwise: true)
      (n as! SKShapeNode).path = path

    }

    c.run(SKAction.repeatForever(SKAction.sequence([cc, dd])))

    self.addChild(c)


/*    let a = ring(size, scale: { (n, tx) in
      let t = tx / ( CGFloat(self.speedx) / 2.0)
      let x = max(0.27-CGFloat(self.strokex), abs(sin(t)))
      let y = self.mix(-0.1, x * 0.6, abs(cos(t / 2)))
//      let z = self.mix(y * 1.2, x * 0.9, abs(sin(t * 0.75) * cos(t * 0.75)))
      n.setScale(y)
      (n as! SKShapeNode).lineWidth = CGFloat(self.strokex) * size.height / y
    })
*/
    /*    float3 rv = float3(0.);
     rv.x = max(0.4, abs(sin(uni.iTime * 1.33)));
     rv.y = mix(0.05, rv.x * 0.6, abs(cos(uni.iTime * 0.66)));
     rv.z = mix(rv.y * 1.2, rv.x * 0.9, abs(sin(uni.iTime) * cos(uni.iTime)));
     rv *= 0.49;
     float radius = rv.z;
     */

    /*
    let b = ring(size, scale: { (n, tx) in
      let t = tx / ( CGFloat(self.speedx) / 2.0)
      let x = max(0.27-CGFloat(self.strokex), abs(sin(t)))
      let y = self.mix(-0.1, x * 0.6, abs(cos(t / 2)))
      let z = self.mix(y * 1.2, x * 0.9, abs(sin(t * 0.75) * cos(t * 0.75)))
      n.setScale(z)
      (n as! SKShapeNode).lineWidth = CGFloat(self.strokex) * size.height / z

    })
*/

    /*
     v.color = float4(float3(min(abs(cos(x)),abs(sin(2*x)))), 1);
     float x = uni.iTime / 3;

     float radius = 0.49 * max(0.4, abs(sin(uni.iTime * 1.33)));
     */

//    self.addChild(c)
//    self.addChild(b)

    // *** I NEED THIS FOR UPDATE ***
    self.isPaused = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func update( _ ti : TimeInterval) {
    //    print("update \(ti)")
  }

}

class Arcs : SKSCNScene {
  override var group : String { get  { "Circles - Scene" } }

  required init() {
    super.init()
    skScene = Arcs_Sprite()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
