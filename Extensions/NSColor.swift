
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
