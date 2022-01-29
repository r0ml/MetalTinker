
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#if os(macOS)
import AppKit
typealias XColor = NSColor

#else
import UIKit
typealias XColor = UIColor
#endif

import MetalKit

#if os(macOS)
extension NSColor {
  func asFloat4() -> SIMD4<Float> {
    return SIMD4<Float>( Float(self.redComponent), Float(self.greenComponent), Float(self.blueComponent), Float(self.alphaComponent))
  }

  convenience init(_ f : SIMD4<Float>) {
    self.init(calibratedRed: CGFloat(f[0]), green: CGFloat(f[1]), blue: CGFloat(f[2]), alpha: CGFloat(f[3]))
  }
}
#endif

#if os(iOS)
extension UIColor {
  func asFloat4() -> SIMD4<Float> {
    var a : CGFloat = 0
    var b : CGFloat = 0
    var c : CGFloat = 0
    var d : CGFloat = 0

    self.getRed(&a, green: &b, blue: &c, alpha: &d)

    return SIMD4<Float>( Float(a), Float(b), Float(c), Float(d))
  }

  convenience init(_ f : SIMD4<Float>) {
    self.init(displayP3Red: CGFloat(f[0]), green: CGFloat(f[1]), blue: CGFloat(f[2]), alpha: CGFloat(f[3]))
  }
}
#endif
