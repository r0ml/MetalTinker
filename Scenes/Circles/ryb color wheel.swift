// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import SpriteKit


func hsv2rgb_subtractive(_ c : SIMD3<Float> ) -> SIMD3<Float> {
  let frac = fract(c.x)*6.0
  var col = smoothstep( SIMD3<Float>(3,0,3),SIMD3<Float>(2,2,4),SIMD3<Float>(repeating: frac))
  col += smoothstep( SIMD3<Float>(4,3,4), SIMD3<Float>(6,4,6), SIMD3<Float>(repeating: frac)) * SIMD3<Float>(1, -1, -1)
  return mix( SIMD3<Float>(repeating: 1), col, SIMD3<Float>(repeating: c.y) ) * c.z;
}


// FIXME: I did not implement the background gradient.
// Probably should do a CIFilter which generates it using a shader.
// then see: https://craiggrummitt.com/2015/03/24/skshapenode-gradient/

 /*

fragmentFn() {
  float2 uv = textureCoord;
  float2 p = worldCoordAspectAdjusted;

  float4 fragColor = 0;

  float frac = (atan2(p.x, -p.y) + PI) / (2.0 * PI);
  frac += 1.0/3.0;
  frac = floor(frac*12.0+0.5)/12.0;

  fragColor.rgb = hsv2rgb_subtractive( float3(frac, 1, 1) );
  float3 back = hsv2rgb_subtractive( float3( uv.x, uv.y, 1.0 - uv.y) );
  float l = abs(length(p) - 0.7);

  return float4( mix(fragColor.rgb, back, smoothstep(0.20, 0.21, l)), 1);

}
*/





class ryb_color_wheel_Sprite : SKScene {
  let speedx = 1.5
  let strokex = 0.04

  func col(_ n : Int) -> SKColor {
    let g = Float(n) / Float(12.0)
    let c = hsv2rgb_subtractive( SIMD3<Float>(g, 1, 1) )
    let d = SIMD4<Float>(c, 1)
    return SKColor(d).toSRGB()
  }

  func wedge(_ size : CGSize, angle : CGFloat, color : SKColor) -> SKShapeNode {


    let eangle = angle + CGFloat.pi / 6
    let sangle = angle

    let path = CGMutablePath()
    path.addArc(center: .zero, radius: 0.45 * size.height, startAngle: sangle, endAngle: eangle, clockwise: false)
    path.addLine(to: CGPoint(x: 0.3 * size.height * cos(eangle), y: 0.3 * size.height * sin(eangle)) )
    path.addArc(center: .zero, radius: 0.25 * size.height, startAngle: eangle, endAngle: sangle , clockwise: true)
    path.closeSubpath()

    let a = SKShapeNode(path: path)
//    a.fillColor = SKColor(cgColor: color)!
    a.fillColor = color
    a.lineWidth = 0
    a.position = CGPoint(x: size.width/2.0, y: size.height/2.0)

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

    /*
    wedge(size, angle: CGFloat.pi / 12, color: CGColor(red: 237 / 255.0, green : 118 / 255.0, blue: 47 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 3 / 12, color: CGColor(red: 245 / 255.0, green : 190 / 255.0, blue: 65 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 5 / 12, color: CGColor(red: 252 / 255.0, green : 237 / 255.0, blue: 79 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 7 / 12, color: CGColor(red: 255 / 255.0, green : 254 / 255.0, blue: 84 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 9 / 12, color: CGColor(red: 202 / 255.0, green : 252 / 255.0, blue: 80 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 11 / 12, color: CGColor(red: 117 / 255.0, green : 250 / 255.0, blue: 76 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 13 / 12, color: CGColor(red: 84 / 255.0, green : 184 / 255.0, blue: 186 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 15 / 12, color: CGColor(red: 6 / 255.0, green : 24 / 255.0, blue: 245 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 17 / 12, color: CGColor(red: 101 / 255.0, green : 30 / 255.0, blue: 228 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 19 / 12, color: CGColor(red: 172 / 255.0, green : 40 / 255.0, blue: 182 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 21 / 12, color: CGColor(red: 217 / 255.0, green : 48 / 255.0, blue: 110 / 255.0, alpha: 1) )
    wedge(size, angle: CGFloat.pi * 23 / 12, color: CGColor(red: 234 / 255.0, green : 51 / 255.0, blue: 35 / 255.0, alpha: 1) )
*/

    for i in 1 ... 12 {
      self.addChild(wedge(size, angle: CGFloat.pi * (2 * CGFloat(i) - 1) / 12, color : col(i) ) )
    }

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

class ryb_color_wheel_Remix : SKSCNScene {
  override var group : String { get  { "Circles - Scene" } }

  required init() {
    super.init()
    skScene = ryb_color_wheel_Sprite()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
