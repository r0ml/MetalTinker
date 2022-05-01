
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

class ShaderFilter : ParameterizedShader {

  var fragmentTextures : [TextureParameter] = []

  private var _renderPassDescriptor : MTLRenderPassDescriptor?
  private var _mySize : CGSize?

  //  private var shadowFrameTexture : MTLTexture?

  override var myGroup : String {
    get { "Filters" }
  }
  

  required init(_ s : String ) {
    super.init(s)
//   function = Function(myGroup)
  }


  override func setupFrame(_ t : Times) {
    for (i,v) in fragmentTextures.enumerated() {
      if let vs = v.video {
        fragmentTextures[i].texture = vs.readBuffer(t.currentTime) //     v.prepare(stat, currentTime - startTime)
      }
    }
  }


  override func specialInitialization() {
    let aa = metadata
    if let bb = aa?.fragmentArguments {
      processTextures(bb)
    }

    super.specialInitialization()
  }

  // let's assume this is where the shader starts running, so shader initialization should happen here.
  override func startRunning() {
    for v in fragmentTextures {
      if let vs = v.video {
        vs.startVideo()
      }
    }
  }

  override func stopRunning() {
    for v in fragmentTextures {
      if let vs = v.video {
        vs.stopVideo()
      }
    }
  }


  override func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?) -> (MTLRenderPipelineState, MTLRenderPipelineReflection, MTLRenderPipelineDescriptor)? {
    // ============================================
    // this is the actual rendering fragment shader

    let psd = MTLRenderPipelineDescriptor()

    psd.vertexFunction = vertexFunction
    psd.fragmentFunction = fragmentFunction
    psd.colorAttachments[0].pixelFormat = thePixelFormat
    psd.isAlphaToOneEnabled = false
    psd.colorAttachments[0].isBlendingEnabled = false // true?
    psd.colorAttachments[0].alphaBlendOperation = .add
    psd.colorAttachments[0].rgbBlendOperation = .add
    psd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha // I would like to set this to   .one   for some cases
    psd.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    psd.colorAttachments[0].destinationRGBBlendFactor =  .destinationAlpha //   doesBlend ? .destinationAlpha : .oneMinusSourceAlpha
    psd.colorAttachments[0].destinationAlphaBlendFactor = .destinationAlpha //   doesBlend ? .destinationAlpha : .oneMinusSourceAlpha

    psd.sampleCount = multisampleCount
    psd.inputPrimitiveTopology = .triangle


    if psd.vertexFunction != nil && psd.fragmentFunction != nil {
      do {
        var metadata : MTLRenderPipelineReflection?
        let res = try device.makeRenderPipelineState(descriptor: psd, options: [.argumentInfo, .bufferTypeInfo], reflection: &metadata)
        if let m = metadata {
          return (res, m, psd)
        }
      } catch let er {
        // let m = "Failed to create render render pipeline state for \(self.label), error \(er.localizedDescription)"
        os_log("%s", type:.error, er.localizedDescription)
        return nil
      }
    } else {
      os_log("vertex or fragment function missing for \(self.myName)")
    }
    return nil
  }


  /** This sets up the initializer by finding the function in the shader,
   using reflection to analyze the types of the argument
   then setting up the buffer which will be the "preferences" buffer.
   It would be the "Uniform" buffer, but that one is fixed, whereas this one is variable -- so it's
   just easier to make it a separate buffer
   */


  private func processTextures(_ bst : [MTLArgument] ) {
    for a in bst {
      if a.type == .texture {
        for z in 0..<a.arrayLength {
          if let b = TextureParameter(a, z, id: fragmentTextures.count) {
            fragmentTextures.append(b)
          }
        }
      }
    }
  }
  


  override func setArguments(_ renderEncoder : MTLRenderCommandEncoder) {
    super.setArguments(renderEncoder)

    for i in 0..<fragmentTextures.count {
      setFragmentTexture(i)
      renderEncoder.setFragmentTexture( fragmentTextures[i].texture, index: fragmentTextures[i].index)
    }
  }


  override func finishCommandEncoding( _ renderEncoder : MTLRenderCommandEncoder) {
    // FIXME: I need to figure out how to clear the render textures at the beginning of a render.
//    if setup.iFrame > 0 {


      super.finishCommandEncoding(renderEncoder)
//    }

  }

  func setFragmentTexture(_ i : Int) {
    if fragmentTextures[i].texture == nil {
      fragmentTextures[i].texture = fragmentTextures[i].image.getTexture(textureLoader, mipmaps: true)
    }
  }

  override func morePrefs() -> [IdentifiableView] {
    let c = self.buildImageWells()
     let d = IdentifiableView(id: "sources", view: AnyView(c))
    return [d]
  }

  func buildImageWells() -> AnyView {
    return AnyView(
      ImageStrip(texes: Binding.init(get: { return self.fragmentTextures } , set: {
      self.fragmentTextures = $0 }))
      )
  }


}
