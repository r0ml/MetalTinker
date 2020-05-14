
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import Accelerate

extension MTLTexture {

  func bytes() -> UnsafeMutableRawPointer {
    let width = self.width
    let height   = self.height
    let rowBytes = self.width * 4
    let p = malloc(width * height * 4)!
    self.getBytes(p, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
    return p
  }

  var cgImage : CGImage? {
    get {
      return CIImage.init(mtlTexture: self, options: [:])?.cgImage
    }
  }
}

