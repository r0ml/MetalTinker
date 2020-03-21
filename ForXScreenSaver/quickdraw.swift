//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

// These routines are for XScreenSaver ports
// probably gets moved to metal:  it generates a series of linse -- so will be passed to vertex shader
//  -- initialized in initFrame
import MetalKit

public func drawArc(center : CGPoint, radius : Float, angle : Range<Float>, segments : Int)  -> [SIMD2<Float>] {
  let theta = (angle.upperBound - angle.lowerBound) / Float(segments - 1)
  let tangetial_factor = tanf(theta)
  let radial_factor = cosf(theta)

  var x = radius * cosf(angle.lowerBound)
  var y = radius * sinf(angle.lowerBound)

  // glBegin(GL_LINE_STRIP);//since the arc is not a closed curve, this is a strip now

  var res = Array<SIMD2<Float>>()

  let cx = Float(center.x)
  let cy = Float(center.y)
  for _ in 0..<segments {
    res.append( SIMD2<Float>(x + cx, y + cy) )

    let tx = -y;
    let ty = x

    x += tx * tangetial_factor
    y += ty * tangetial_factor

    x *= radial_factor
    y *= radial_factor
  }
  res.append( SIMD2<Float>(x + cx, y+cy) )
  return res
}
