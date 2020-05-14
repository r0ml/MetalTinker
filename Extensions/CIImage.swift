
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import CoreImage
import AppKit

let TheCIContext = CIContext() // .init(mtlDevice: device)

extension CIImage {
  var nsImage : NSImage? {
    get {
      guard let cgImg = TheCIContext.createCGImage(self.oriented(.downMirrored), from: self.extent) else { return nil }
      return NSImage(cgImage: cgImg, size: CGSize(width: cgImg.width, height: cgImg.height))
    }
  }

  var cgImage : CGImage? {
    get {
      return TheCIContext.createCGImage(self.oriented(.downMirrored), from: self.extent, format: .ARGB8, colorSpace:
        CGColorSpace.init(name: CGColorSpace.sRGB)) // CGColorSpaceCreateDeviceRGB() )
    }
  }

}

