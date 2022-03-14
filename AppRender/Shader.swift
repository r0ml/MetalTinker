
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#if os(macOS)
import AppKit
#endif

import MetalKit
import os
import AVFoundation

/*
 I have to split Shader into the Model for MetalViewState, and the model for the shader.
 MetalViewState is the singleton which manages the state of the metal view, and there is only one of those.
 
 Shader tracks the stuff which is different for different shaders.
 */

public let device = MTLCreateSystemDefaultDevice()!
public let commandQueue = device.makeCommandQueue()!


let thePixelFormat = MTLPixelFormat.bgra8Unorm_srgb // could be bgra8Unorm_srgb
// let theOtherPixelFormat = MTLPixelFormat.bgra8Unorm_srgb

let multisampleCount = 4

let uniformId = 2
let kbuffId = 3
let computeBuffId = 15

// This is for debugging -- the regular way doesn't work in so many cases
// var myCaptureScope = MTLCaptureManager.shared().makeCaptureScope(device: device)


/** This class is responsible for rendering the MetalView (building the render pipeline) */
protocol Shader : Identifiable {
  associatedtype Config
  
  var myName : String { get set }
  func setupFrame(_ times : Times) // used to be grabVideo
  var config : Config { get }
  init(_ s : String)
  func draw(in viewx: MTKView, delegate : MetalDelegate<Self>)
  func startRunning()
}

extension Shader {
  static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.myName == rhs.myName
  }
  
  public var id : String {
    return myName
  }
  
}


func makeRenderPassTexture(_ nam : String, size: CGSize) -> (MTLTexture, MTLTexture, MTLTexture)? {
  let texd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
  texd.textureType = .type2DMultisample
  texd.usage = [.renderTarget]
  texd.sampleCount = multisampleCount
  texd.resourceOptions = .storageModePrivate
  
  let texi = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */ , width: Int(size.width), height: Int(size.height), mipmapped: true)
  texi.textureType = .type2D
  texi.usage = [.shaderRead]
  texi.resourceOptions = .storageModePrivate
  
  let texo = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
  texo.textureType = .type2D
  texo.usage = [.renderTarget, .shaderWrite, .shaderRead] // or just renderTarget -- the read is in case the texture is used in a filter
  texo.resourceOptions = .storageModePrivate
  
  if let p = device.makeTexture(descriptor: texd),
     let q = device.makeTexture(descriptor: texi),
     let r = device.makeTexture(descriptor: texo) {
    p.label = "render pass \(nam) multisample"
    q.label = "render pass \(nam) input"
    r.label = "render pass \(nam) output"
    //        swapQ.async {
    
    
    
    return (p, q, r)
  }
  return nil
}

func makeRenderPassDescriptor(label : String, size canvasSize: CGSize) -> MTLRenderPassDescriptor {
  //------------------------------------------------------------
  // texture on device to be written to..
  //------------------------------------------------------------
  let ts = makeRenderPassTexture(label, size: canvasSize)!
  let texture = ts.0
  let resolveTextures = (ts.1, ts.2)
  
  let renderPassDescriptor = MTLRenderPassDescriptor()
  renderPassDescriptor.colorAttachments[0].texture = texture
  renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
  renderPassDescriptor.colorAttachments[0].resolveLevel = 0
  renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTextures.1 //  device.makeTexture(descriptor: xostd)
  renderPassDescriptor.colorAttachments[0].loadAction = .clear // .load
  //      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)
  
  
  // only if I need depthing?
  renderPassDescriptor.depthAttachment = RenderPipelinePass.makeDepthAttachmentDescriptor(size: canvasSize)
  
  return renderPassDescriptor
}

extension Shader {
  /** when the window resizes ... */
  /*  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
   if self.mySize?.width != size.width || self.mySize?.height != size.height {
   // print("got a size update \(mySize) -> \(size)")
   // FIXME:
   // self.makeRenderPassTextures(size: size)
   self.config.pipelinePasses.forEach { ($0 as? RenderPipelinePass)?.resize(size) }
   } else {
   // print("got a size update message when the size didn't change \(size)")
   }
   self.mySize = size;
   }
   */
  
  
}


