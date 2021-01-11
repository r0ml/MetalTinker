// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SpriteKit

// In order to handle interaction, I need to subclass SKScene
// (for things like didMove()?  and definitely  touchesBegan

class Simple3 : SKScene {

  override required init() {
    let size = CGSize(width: 800, height: 500)
    super.init(size: size)
    self.scaleMode = .aspectFit

    let a = SKShapeNode(circleOfRadius: size.height / 3.0)
    a.strokeColor = SKColor.green
    a.fillColor = SKColor.blue
    a.lineWidth = 0.8
    a.glowWidth = 0

    a.position = CGPoint(x: size.width/2.0, y: size.height/2.0)

//    a.position = CGPoint(x: size.width / 2, y: 400)
    a.physicsBody?.isDynamic = false
    
    self.addChild(a)

    let b = SKLabelNode(text: "hello, this is SpriteKit")
    b.horizontalAlignmentMode = .left
    b.position = CGPoint(x: 10, y: 10)
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
