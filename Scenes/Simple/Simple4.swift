// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit

class Simple4 : T3SCNScene {
  override var group : String  { get { "Simple" } }

  required init() {
    super.init()
    let k = Simple3()

    let a = SCNFloor()
    let mat = SCNMaterial()
    mat.diffuse.contents = k
    mat.diffuse.wrapS = .repeat
    mat.diffuse.wrapT = .repeat

    mat.diffuse.contentsTransform = SCNMatrix4MakeScale(20 * (k.size.height / k.size.width), -20, 0)
//    mat.transparencyMode = .singleLayer
//    mat.transparency = 1

    a.materials = [mat]
    mat.isDoubleSided = true
    let na = SCNNode(geometry: a)

    let b = SCNTorus.init(ringRadius: 0.6, pipeRadius: 0.2)
    let mat2 = SCNMaterial()
    mat2.diffuse.contents = NSColor.blue
    b.materials = [mat2]
    let nb = SCNNode(geometry: b)

    self.rootNode.addChildNode(na)
    self.rootNode.addChildNode(nb)


    self.background.contents = NSColor.black
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

/*
 const CGFloat DIVISOR = 255.0f;
    CIColor *bottomColor = [CIColor colorWithRed:(CGFloat)0xee / DIVISOR green:(CGFloat)0x78 / DIVISOR blue:(CGFloat)0x0f / DIVISOR alpha:1];
    CIColor *topColor = [CIColor colorWithRed:0xff / DIVISOR green:0xfb / DIVISOR blue:0xcf / DIVISOR alpha:1];
    SKTexture* textureGradient = [SKTexture textureWithVerticalGradientofSize:scnview.frame.size topColor:topColor bottomColor:bottomColor];
    UIImage* uiimageGradient = [UIImage imageWithCGImage:textureGradient.CGImage];
    self.background.contents = uiimageGradient;
 */
