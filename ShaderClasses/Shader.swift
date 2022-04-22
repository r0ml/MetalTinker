
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#if os(macOS)
import AppKit
#endif

import MetalKit
import os
import AVFoundation
import SwiftUI

/*
 I have to split Shader into the Model for MetalViewState, and the model for the shader.
 MetalViewState is the singleton which manages the state of the metal view, and there is only one of those.
 
 Shader tracks the stuff which is different for different shaders.
 */

public let device = MTLCreateSystemDefaultDevice()!
public let commandQueue = device.makeCommandQueue()!
public var textureLoader = MTKTextureLoader(device: device)


let thePixelFormat = MTLPixelFormat.bgra8Unorm // could be bgra8Unorm_srgb
                                                    // let theOtherPixelFormat = MTLPixelFormat.bgra8Unorm_srgb

let multisampleCount = 4

let uniformId = 2
let kbuffId = 3
let computeBuffId = 15

// This is for debugging -- the regular way doesn't work in so many cases
// var myCaptureScope = MTLCaptureManager.shared().makeCaptureScope(device: device)


/** This class is responsible for rendering the MetalView (building the render pipeline) */
/*
 protocol Shader : Identifiable {
  var myName : String { get set }
  func setupFrame(_ times : Times) // used to be grabVideo
  init(_ s : String)
  func draw(in viewx: MTKView, delegate : MetalDelegate)
  func startRunning()
  func stopRunning()
  func buildPrefView() -> [IdentifiableView]
  func renderPassDescriptor(_ s : CGSize) -> MTLRenderPassDescriptor
}
*/

/*
extension Shader {
//  static func == (lhs: Self, rhs: Self) -> Bool {
//    return lhs.myName == rhs.myName
//  }
  
  public var id : String {
    return myName
  }
  
}
*/
