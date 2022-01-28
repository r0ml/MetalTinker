// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import SpriteKit
import SwiftUI

class Rotating_LED_Strip_Sprite : SKScene {
  let speedx = 1.5
  let strokex = 0.04

  func top() -> SKShapeNode {
    let path = CGMutablePath()
    path.move(to: .zero)
    let rrat : CGFloat = 0.3 * 0.9 * 0.5
    path.addLine(to: CGPoint(x: 0.5 - (rrat * 0.5), y: 0))
    path.addArc(center: CGPoint(x: 0.5, y: 0), radius: rrat, startAngle: CGFloat.pi, endAngle: 0, clockwise: true)
    path.addLine(to: CGPoint(x: 2.5 - (rrat * 0.5), y: 0))
    path.addArc(center: CGPoint(x: 2.5, y: 0), radius: rrat, startAngle: CGFloat.pi, endAngle: 0, clockwise: true)
    path.addLine(to: CGPoint(x: 3, y: 0))
    path.addLine(to: CGPoint(x: 3, y: 1))
    path.addLine(to: CGPoint(x: 0, y: 1))
    path.addLine(to: CGPoint(x: 0, y:0))

    path.move(to: CGPoint(x: 1.5, y: 0.5 + rrat * 2))
    path.addArc(center: CGPoint(x: 1.5, y: 0.5), radius: rrat * 2, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)

    let a = SKShapeNode(path: path)
    a.fillColor = XColor.white
    a.lineWidth = 0
    a.isAntialiased = true
    return a
  }

  func thing() -> SKShapeNode {
    let color = XColor.white
    let path = CGMutablePath()

    let rrat : CGFloat = 0.3 //  CGFloat.pi / 11
    let rr : CGFloat = rrat * 0.5
    let r2 : CGFloat = 0.5

    let theta : CGFloat = 0.27 // atan(rrat) // 0.27
    let phi : CGFloat = asin( sin(theta) / rrat)
    let ctr : CGFloat = (cos(theta) + cos(phi) * rrat) * 0.5

    path.addArc(center: CGPoint(x: ctr, y: 0), radius: rr, startAngle: CGFloat.pi + phi, endAngle: CGFloat.pi - phi, clockwise: true )
    path.addArc(center: CGPoint(x: 0, y: 0), radius: r2, startAngle: theta, endAngle: CGFloat.pi / 2 - theta, clockwise: false)

    path.addArc(center: CGPoint(x: 0, y: ctr), radius: rr, startAngle: CGFloat.pi * 1.5 + phi, endAngle: CGFloat.pi * 1.5 - phi, clockwise: true )
    path.addArc(center: CGPoint(x: 0, y: 0), radius: r2, startAngle: CGFloat.pi / 2 + theta, endAngle: CGFloat.pi - theta, clockwise: false)

    path.addArc(center: CGPoint(x: -ctr, y: 0), radius: rr, startAngle: phi, endAngle: -phi, clockwise: true )
    path.addArc(center: CGPoint(x: 0, y: 0), radius: r2, startAngle: CGFloat.pi + theta, endAngle: CGFloat.pi * 1.5 - theta, clockwise: false)

    path.addArc(center: CGPoint(x: 0, y: -ctr), radius: rr, startAngle: CGFloat.pi * 0.5 + phi, endAngle: CGFloat.pi * 0.5 - phi, clockwise: true )
    path.addArc(center: CGPoint(x: 0, y: 0), radius: r2, startAngle: CGFloat.pi * 1.5 + theta, endAngle: CGFloat.pi * 2 - theta, clockwise: false)

//    path.addLine(to: CGPoint(x: 0.3 * size.height * cos(eangle), y: 0.3 * size.height * sin(eangle)) )
//    path.addArc(center: .zero, radius: 0.25 * size.height, startAngle: eangle, endAngle: sangle , clockwise: true)
//    path.closeSubpath()

    path.move(to: CGPoint(x: rr, y: 0))
    path.addArc(center: CGPoint(x: 0, y: 0), radius: rr, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)

    let a = SKShapeNode(path: path)
//    a.fillColor = SKColor(cgColor: color)!
    a.fillColor = color
    a.lineWidth = 0
    a.isAntialiased = true
    // a.strokeColor = NSColor.red
    // a.position = CGPoint(x: size.width/2.0, y: size.height/2.0)

    return a
  }

  override required init() {
    let size = CGSize(width: 6400, height: 3600)
    super.init(size: size)
    self.scaleMode = .aspectFit

    self.backgroundColor = XColor.darkGray

    for i in 0 ..< 9 {
      let a = thing()
      let (b, c) = i.quotientAndRemainder(dividingBy: 3)

      // let ll = CGFloat(1 / 1.4 / 2) // 0.357
      let ll : CGFloat = 0.33
      a.position = CGPoint(x: (ll + CGFloat(1) / 8 + CGFloat(b) / 4 ) * size.height, y: (CGFloat(1) / 8 +  CGFloat(c) / 4) * size.height )
      a.setScale( size.height / 4 * 0.9)

      let dur = Double.pi / 2
      let d = SKAction.rotate(byAngle: CGFloat.pi / 2 * ((i % 2) == 0 ? -1 : 1), duration: dur)
      let e = SKAction.wait(forDuration: dur)
      let bb = SKAction.sequence([d, e])
      let cc = SKAction.repeatForever(bb)
      a.run(cc)
      self.addChild(a)
    }

    let ta = top()
    ta.setScale( size.height / 4)
    ta.position = CGPoint(x: 0.33 * size.height, y: 0.75 * size.height)

    self.addChild(ta)

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

class Rotating_LED_Strip : SKSCNScene {
  override var group : String { get  { "Circles - Scene" } }

  required init() {
    super.init()
    skScene = Rotating_LED_Strip_Sprite()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
