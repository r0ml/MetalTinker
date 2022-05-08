
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
#if os(macOS)
import AppKit
#endif

import MetalKit
import os
import SwiftUI

/// A VideoStream is either a VideoSupport (for playing video files)  or a WebcamSupport (for playing the live camera)
protocol VideoStream {
  func readBuffer(_ nVSync : TimeInterval) -> MTLTexture?
  func stopVideo()
  func startVideo()
}


class BufferParameter : Identifiable {
  typealias ObjectIdentifier = Int
  var id : ObjectIdentifier

  var index : Int
  var buffer : MTLBuffer?
  var name : String
  var type : MTLDataType

  init?(_ a : MTLArgument, _ n : Int, id: Int) {
    self.id = id
    if a.type == .buffer {
      name = a.name
      index = a.index + n
      type = a.bufferDataType
      if let b = device.makeBuffer(length: a.bufferDataSize) {
        buffer = b
      } else {
        return nil
      }
    } else {
      return nil
    }
  }
}

/** This class processes the initializer and sets up the shader parameters based on the shader defaults and user defaults */
class TextureParameter : Identifiable {
  typealias ObjectIdentifier = Int
  var id : ObjectIdentifier

  var index : Int
  var type : MTLTextureType
  var access : MTLArgumentAccess
  var data : MTLDataType
  var image : XImage
  var video : VideoStream?
  var texture : MTLTexture?
  var name : String

  init?(_ a : MTLArgument, _ n : Int, id: Int) {
    self.id = id
    if a.type == .texture {
      name = a.name
      index = a.index + n
      type = a.textureType
      access = a.access
      data = a.textureDataType
      image = XImage.init(named: ["london", "flagstones", "water", "wood", "still_life"][a.index % 5] )!
    } else {
      return nil
    }

//    if a.name == "lastFrame" {
//      print("lastFrame texture")
//    }

  }

  func setTexture(_ t : MTLTexture) {
    texture = t
  }
}
