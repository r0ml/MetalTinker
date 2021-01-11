// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import SpriteKit

class Bello_Sprite : SKScene {
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
    self.backgroundColor = // SKColor.init(srgbRed: 0.4, green: 0.6, blue: 1, alpha: 1).usingColorSpace(.extendedSRGB)!
      //      SKColor.init(srgbRed: pow(0.4, j), green: pow( 0.6, j), blue: pow(1, j), alpha: 1)
      SKColor.init(red: 0.4, green: 0.6, blue: 1, alpha: 1).toSRGB()

    /*    float3 rv = float3(0.);
     rv.x = max(0.4, abs(sin(uni.iTime * 1.33)));
     rv.y = mix(0.05, rv.x * 0.6, abs(cos(uni.iTime * 0.66)));
     rv.z = mix(rv.y * 1.2, rv.x * 0.9, abs(sin(uni.iTime) * cos(uni.iTime)));
     rv *= 0.49;

     float radius = rv.y;
     */
    let a = ring(size, scale: { (n, tx) in
      let t = tx / ( CGFloat(self.speedx) / 2.0)
      let x = max(0.27-CGFloat(self.strokex), abs(sin(t)))
      let y = mix(-0.1, x * 0.6, abs(cos(t / 2)))
//      let z = self.mix(y * 1.2, x * 0.9, abs(sin(t * 0.75) * cos(t * 0.75)))
      n.setScale(y)
      (n as! SKShapeNode).lineWidth = CGFloat(self.strokex) * size.height / y
    })

    /*    float3 rv = float3(0.);
     rv.x = max(0.4, abs(sin(uni.iTime * 1.33)));
     rv.y = mix(0.05, rv.x * 0.6, abs(cos(uni.iTime * 0.66)));
     rv.z = mix(rv.y * 1.2, rv.x * 0.9, abs(sin(uni.iTime) * cos(uni.iTime)));
     rv *= 0.49;
     float radius = rv.z;
     */
    let b = ring(size, scale: { (n, tx) in
      let t = tx / ( CGFloat(self.speedx) / 2.0)
      let x = max(0.27-CGFloat(self.strokex), abs(sin(t)))
      let y = mix(-0.1, x * 0.6, abs(cos(t / 2)))
      let z = mix(y * 1.2, x * 0.9, abs(sin(t * 0.75) * cos(t * 0.75)))
      n.setScale(z)
      (n as! SKShapeNode).lineWidth = CGFloat(self.strokex) * size.height / z

    })


    /*
     v.color = float4(float3(min(abs(cos(x)),abs(sin(2*x)))), 1);
     float x = uni.iTime / 3;

     float radius = 0.49 * max(0.4, abs(sin(uni.iTime * 1.33)));
     */
    let c = ring(size, scale: { (n : SKNode, tx : CGFloat) in
      let t = tx / (CGFloat(self.speedx)  / 2)
      let ss = max(0.27, abs(sin(t)))
      n.setScale( ss )
      (n as! SKShapeNode).lineWidth = CGFloat(self.strokex) * size.height / ss
      let tt = Float(t) / 4
      let k : Float = min(abs(cos(tt)), abs(sin(2*tt)))
      let kk = SIMD4<Float>.init(k,k,k,1)
      let kkk : SKColor = SKColor(kk).toSRGB()
      (n as! SKShapeNode).strokeColor = kkk
    } )


    self.addChild(c)
    self.addChild(b)
    self.addChild(a)

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

class Bello : SKSCNScene {
  override var group : String { get  { "Circles - Scene" } }
  override var skScene : SKScene { get { Bello_Sprite() }}
}
