
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import os
import SwiftUI
import SceneKit

#if targetEnvironment(macCatalyst)
import UIKit
#endif

/* TODO:
 1) There is a flicker when resuming after pause (on macCatalyst).  The first frame after pause seems to (someetimes) be frame 0 -- not the current frame
 2) Can I update the thumbnail as the video plays?
 3) Single step is not working
 4) recording and snapshotting is not working
 5) instead of using a separate initialization function in the shader, I could use the fragment function (which also has the "in" parameter) and have the shader macro call initialize() on frame 0
 6) Camera sometimes doesn't shut off when moving to different shader.
 7) Need to set the zoom explicitly (it stays set to previous user -- so Librorum altered it -- for MacOS only it seems
 8) aspect ratio seems off for MacOS on second camera
 9) Switching cameras doesn't turn off the one being switched away from (macOS)
 10) Snapshot icon doesn't show up for MacCatalyst
 */

class ShaderFeedback : ShaderFilter {

  private var lastFrameTextures : [MTLTexture]?
  var renderPipelineDescriptor : MTLRenderPipelineDescriptor?

  override var myGroup : String {
    get { "Feedback" }
  }

  override func specialInitialization() {
    super.specialInitialization()

    let k = fragmentTextures.filter({ $0.name == "lastFrame" }).count
    if k > 1 {
      for j in 1..<k {
        self.renderPipelineDescriptor?.colorAttachments[j].pixelFormat = .rgba32Float
      }
      if let rs = self.renderPipelineDescriptor,
         let ps = try? device.makeRenderPipelineState(descriptor: rs) {
        self.pipelineState = ps
      }

    }

  }

  override func buildImageWells() -> AnyView {

    // FIXME: filter out the "lastFrame" textures (and the shadow textures)
    // I believe this is where the ImageStrip sets the images as texture inputs.
    // It is also where the webcam and video support should be assigned
   AnyView(
    ImageStrip(texes: Binding.init(get: { return self.fragmentTextures.filter({ $0.name != "lastFrame" })  }, set: {
      self.fragmentTextures = $0 }))
    )
  }

  var shadows : [(MTLTexture, MTLTexture)] = []

  // FIXME: when I fix RenderPassPipeline -- move this out of the class
  func makeLastFrameTextures(size: CGSize) {
    if let lf = lastFrameTextures,
       lf.count > 0,
       lf[0].width == Int(size.width),
       lf[0].height == Int(size.height) {

    } else {

      lastFrameTextures = []
      shadows = []

      let z = fragmentTextures.filter { $0.name == "lastFrame" }
      if z.count == 0 {
      } else {

        let texl = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float /* thePixelFormat */ /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
        texl.textureType = .type2D
        texl.usage = [.shaderRead] // or just renderTarget -- the read is in case the texture is used in a filter
        texl.resourceOptions = .storageModeManaged


        let texlx = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: thePixelFormat /* theOtherPixelFormat */, width: Int(size.width), height: Int(size.height), mipmapped: false)
        texlx.textureType = .type2D
        texlx.usage = [.shaderRead] // or just renderTarget -- the read is in case the texture is used in a filter
        texlx.resourceOptions = .storageModeManaged

        // FIXME: should the feedback texture be the multisample size texture instead of the resolve texture?

        for (j, k) in z.enumerated() {
          if j > 0 {
            if let pq = makeRenderPassTexture("last frame \(j)", format: .rgba32Float, scale: multisampleCount, size: size) {
            shadows.append(pq)
          }
          }
          if  let s = device.makeTexture(descriptor: j == 0 ? texlx : texl) {
            s.label = "render pass \(j) last frame"
            lastFrameTextures!.append(s)
            k.texture = s
          }
        }
        }

      }

    for j in 0 ..< shadows.count {
      self.renderPassDescriptor?.colorAttachments[j+1].texture = shadows[j].0
      self.renderPassDescriptor?.colorAttachments[j+1].resolveTexture = shadows[j].1
        self.renderPassDescriptor?.colorAttachments[j+1].storeAction = .storeAndMultisampleResolve
      self.renderPassDescriptor?.colorAttachments[j+1].loadAction = .clear
      self.renderPassDescriptor?.colorAttachments[j+1].clearColor = MTLClearColor.init(red: 0, green: 0, blue: 0, alpha: 1)
    }
  }


  override func fixme(_ rpd : MTLRenderPassDescriptor) {
    if let ca = rpd.colorAttachments[1] {

//    ca.pixelFormat = .rgba32Float
    ca.texture = shadows[0].0
      ca.resolveTexture = self.shadows[0].1
    ca.storeAction = .storeAndMultisampleResolve
    ca.loadAction = .clear
    ca.clearColor = MTLClearColor.init(red:0, green: 0, blue: 0, alpha: 1)
    }
  }


  // this sets up the GPU for evaluating the frame
  // gets called both for on and off-screen rendering
  override func doRenderEncoder4(_ commandBuffer : MTLCommandBuffer, _ size : CGSize, _ rpd : MTLRenderPassDescriptor) {
    makeLastFrameTextures( size: size )

    makeEncoder(commandBuffer, multisampleCount, rpd)

        if let kt = lastFrameTextures,
           kt.count > 0,
           let be = commandBuffer.makeBlitCommandEncoder() {
          for i in 0 ..< kt.count {
             if let rt = rpd.colorAttachments[i].resolveTexture {
              be.copy(from: rt, to: kt[i])
              //          be.generateMipmaps(for: ri.1)
              //          be.synchronize(resource: kt)
            }
          }
          be.endEncoding()
        }
        // ========================================================================
    }

  override func setFragmentTexture(_ i : Int) {
    if fragmentTextures[i].texture == nil && fragmentTextures[i].name != "lastFrame" {
      fragmentTextures[i].texture = fragmentTextures[i].image.getTexture(textureLoader, mipmaps: true)
    }
  }

  override func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?) -> (MTLRenderPipelineState, MTLRenderPipelineReflection, MTLRenderPipelineDescriptor)? {
    let j = super.setupRenderPipeline(vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)
    if let j = j {
      self.renderPipelineDescriptor = j.2
    }
    return j
  }

}

