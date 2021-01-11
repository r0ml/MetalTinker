// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

func clamp<T> (_ x : T, _ minVal : T, _ maxVal : T) -> T where T : FloatingPoint {
  return min(max(x, minVal), maxVal)
}

func clamp<T> (_ x : T, _ minVal : T, _ maxVal : T) -> T where T : SIMD, T.Scalar : FloatingPoint {
  return x.clamped(lowerBound: minVal, upperBound: maxVal)
}

func smoothstep<T>(_ edge0 : T, _ edge1 : T, _ x : T) -> T where T : FloatingPoint {
  let x1 = x - edge0
  let x2 = edge1 - edge0
  let y = x1 / x2
  let t : T = clamp(y, 0.0 as! T, 1.0 as! T)
  return t
//   return t * t * (3.0 - 2.0 * t)
}

func smoothstep<T>(_ edge0 : T, _ edge1 : T, _ x : T) -> T where T : SIMD, T.Scalar : FloatingPoint {
  let x1 = x - edge0
  let x2 = edge1 - edge0
  let y = x1 / x2
  let t : T = clamp(y, T.init(repeating: T.Scalar(Int(0.0))), T.init(repeating: T.Scalar(Int(1.0))) )
  return t
//   return t * t * (3.0 - 2.0 * t)
}




func mix<T>(_ x : T, _ y : T, _ a : T) -> T where T : Numeric {
  return x * (1-a) + y * a
}

func mix<T>(_ x : T, _ y : T, _ a : T) -> T where T : SIMD, T.Scalar : FloatingPoint {
  return x * (1-a) + y * a
}



func fract<T>(_ x : T) -> T where T : FloatingPoint {
  return x.truncatingRemainder(dividingBy: 1)
}

func fract<T>(_ x : T) -> T where T : SIMD, T.Scalar : FloatingPoint {
  let y = x.rounded(.down)
  return x - y
}
