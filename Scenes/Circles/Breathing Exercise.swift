// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import SpriteKit


class Breathing_Exercise_Sprite : SKScene {

  override required init() {
    let size = CGSize(width: 1400, height: 1000)
    super.init(size: size)
    self.scaleMode = .aspectFit

    // let j : CGFloat = 1 / sqrt(5)
    self.backgroundColor = // SKColor.init(srgbRed: 0.4, green: 0.6, blue: 1, alpha: 1).usingColorSpace(.extendedSRGB)!
//      SKColor.init(srgbRed: pow(0.4, j), green: pow( 0.6, j), blue: pow(1, j), alpha: 1)
      SKColor.init(red: 0.4, green: 0.6, blue: 1, alpha: 1).toSRGB()

    let a = SKShapeNode(circleOfRadius: 0.2 * size.height )
    a.fillColor = SKColor.white
    a.glowWidth = 0
    a.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
    a.physicsBody?.isDynamic = false


    let action = SKAction.scale(to: 0.25, duration: Double.pi)
    //    action.timingMode = .easeInEaseOut
    action.timingFunction = {
      (time : Float) -> Float in return  time == 1 ? 1 : 1.0 - cos(0.5 * Float.pi * time )
      //      return 1+sin(Float.pi * time)
    }
    let action2 = SKAction.scale(to: 1, duration: Double.pi)
    //  action2.timingMode = .easeInEaseOut
    action2.timingFunction = {
      (time : Float) -> Float in return sin(0.5 * Float.pi * time)
    }

    // let action2 = SKAction.scale(to: 1, duration: 1.5)
    a.run(SKAction.repeatForever(SKAction.sequence([action, action2])))

    let b = SKShapeNode(circleOfRadius: 0.25 * size.height)
    b.fillColor =   SKColor.init(red: 0.35, green: 0.55, blue: 0.95, alpha: 1).toSRGB()
    b.glowWidth = 0
    b.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
    b.physicsBody?.isDynamic = false
    //    b.strokeColor = b.fillColor
    b.lineWidth = 0

    let a3 = SKAction.scale(to: 1.2, duration: Double.pi)
    a3.timingFunction = { (time : Float) -> Float in time == 1 ? 1 : 1.0 - cos(0.5 * Float.pi * time ) }
    let a4 = SKAction.scale(to: 1, duration: Double.pi)
    a4.timingFunction = { time in sin(0.5 * Float.pi * time) }
    b.run(SKAction.repeatForever(SKAction.sequence([a3, a4])))

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

class Breathing_Exercise_Remix : SKSCNScene {
  override var group : String { get  { "Circles - Scene" } }

  required init () {
    super.init()
  }

  override func draw() {
    skScene = Breathing_Exercise_Sprite()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
