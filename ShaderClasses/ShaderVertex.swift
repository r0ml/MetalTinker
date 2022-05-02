
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

let ctrlBuffId = 4

final class ShaderVertex : ShaderFeedback {

  private var controlBuffer : MTLBuffer!

  override var myGroup : String {
    get { "Vertex" }
  }
  

  required init(_ s : String ) {
    //    print("ShaderFilter init \(s)")
    super.init(s)
//    function = Function(myGroup)
  }


  override func setupFrame(_ t : Times) {
    for (i,v) in fragmentTextures.enumerated() {
      if let vs = v.video {
        fragmentTextures[i].texture = vs.readBuffer(t.currentTime) //     v.prepare(stat, currentTime - startTime)
      }
    }
  }

  override func doInitialization( ) {
    super.doInitialization()
    controlBuffer = device.makeBuffer(length: MemoryLayout<ControlBuffer>.stride, options: [.storageModeShared] )!
    let c = controlBuffer.contents().assumingMemoryBound(to: ControlBuffer.self)
    c.pointee.topology = 3
    c.pointee.vertexCount = 4
    c.pointee.instanceCount = 1

  }

  override func setupRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?) -> (MTLRenderPipelineState, MTLRenderPipelineReflection, MTLRenderPipelineDescriptor)? {
    // ============================================
    // this is the actual rendering fragment shader

    let psd = MTLRenderPipelineDescriptor()

    psd.vertexFunction = vertexFunction
    psd.fragmentFunction = fragmentFunction
    psd.colorAttachments[0].pixelFormat = thePixelFormat
    psd.isAlphaToOneEnabled = false
    psd.colorAttachments[0].isBlendingEnabled = true
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


  override func finishCommandEncoding(_ renderEncoder : MTLRenderCommandEncoder ) {

    renderEncoder.setVertexBuffer( controlBuffer, offset: 0, index: ctrlBuffId)
    // end of vertex add

    renderEncoder.setRenderPipelineState(pipelineState)

    let c = controlBuffer.contents().assumingMemoryBound(to: ControlBuffer.self)



    // A filter render encoder takes a single instance of a rectangle (4 vertices) which covers the input.
    let t = Int(c.pointee.topology)
    if t >= 0 && t <= 3 {
      let topo : MTLPrimitiveType = [.point, .line, .triangle, .triangleStrip][t]

      renderEncoder.drawPrimitives(type: topo, vertexStart: 0, vertexCount: Int(c.pointee.vertexCount), instanceCount: Int(c.pointee.instanceCount) )
    }

  }

  override func beginFrame(_ cqq : MTLCommandQueue) {
    //        print("start \(#function)")

    /*      // FIXME: I want the render pipeline metadata

     if let gg = cpr?.arguments.first(where: { $0.name == "in" }),
     let ib = device.makeBuffer(length: gg.bufferDataSize, options: [.storageModeShared ]) {
     ib.label = "defaults buffer for \(self.myName)"
     ib.contents().storeBytes(of: 0, as: Int.self)
     initializationBuffer = ib
     } else if let ib = device.makeBuffer(length: 8, options: [.storageModeShared]) {
     ib.label = "empty kernel compute buffer for \(self.myName)"
     initializationBuffer = ib
     } else {
     os_log("failed to allocate initialization MTLBuffer", type: .fault)
     return
     }
     */


    if let fips = frameInitializePipelineState,
       let commandBuffer = cqq.makeCommandBuffer(),
       let computeEncoder = commandBuffer.makeComputeCommandEncoder()
    {
      commandBuffer.label = "Frame Initialize command buffer for \(self.myName)"
      computeEncoder.label = "frame initialization and defaults encoder \(self.myName)"
      computeEncoder.setComputePipelineState(fips)
      //        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
      computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)
      computeEncoder.setBuffer(controlBuffer, offset: 0, index: ctrlBuffId)

      let ms = MTLSize(width: 1, height: 1, depth: 1);
      computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
      computeEncoder.endEncoding()

      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed
    }

    // at this point, the frame initialization (ctrl) buffer has been set
    // FIXME: I should probably add a compute buffer to hold values across frames?

    /*    if let gg = cpr?.arguments.first(where: { $0.name == "in" }) {
     inbuf = MyMTLStruct.init(initializationBuffer, gg)
     processArguments(inbuf)
     }
     */


  }

  override func beginShader() {
    //    print("start \(#function)")

    if let ips = initializePipelineState,
       let commandBuffer = commandQueue.makeCommandBuffer(),
       let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
      commandBuffer.label = "Initialize command buffer for \(self.myName) "
      computeEncoder.label = "initialization and defaults encoder \(self.myName)"
      computeEncoder.setComputePipelineState(ips)
      //        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
      computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)
      computeEncoder.setBuffer(controlBuffer, offset: 0, index: ctrlBuffId)

      let ms = MTLSize(width: 1, height: 1, depth: 1);
      computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
      computeEncoder.endEncoding()

      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed


      // at this point, the initialization (preferences) buffer has been set
      if let gg = initializeReflection?.arguments.first(where: { $0.name == "in" }) {
        inbuf = MyMTLStruct.init(initializationBuffer, gg)
        processArguments(inbuf)
      }

      getClearColor(inbuf)
    }
  }


  override func makeEncoder(_ kk : RSetup,
                            _ commandBuffer : MTLCommandBuffer,
                           _ scale : Int,
                           _ rpd : MTLRenderPassDescriptor
//                            , delegate : MetalDelegate
  ) {

    // to get the running shader to match the preview?
    // FIXME: do I have clearColor?
    //    if let cc = rm.metalView?.clearColor {
    //      rpd.colorAttachments[0].clearColor = cc


    // FIXME: should this be a clear or load?
    rpd.colorAttachments[0].loadAction = .clear // .load
    rpd.colorAttachments[0].storeAction = .multisampleResolve
    //    }

    let sz = CGSize(width : rpd.colorAttachments[0].texture!.width, height: rpd.colorAttachments[0].texture!.height )
    iFrame += 1
    kk.setupUniform(iFrame: iFrame, size: sz, scale: Int(scale), uniform: uniformBuffer!, times: times )

    // texture and resolveTexture size mismatch    during resize
    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder"

      renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setFragmentBuffer(initializationBuffer, offset: 0, index: kbuffId)
      for i in 0..<fragmentTextures.count {
        if fragmentTextures[i].texture == nil && fragmentTextures[i].name != "lastFrame" && fragmentTextures[i].name != "shadowFrame" {
          fragmentTextures[i].texture = fragmentTextures[i].image.getTexture(textureLoader, mipmaps: true)
        }
        renderEncoder.setFragmentTexture( fragmentTextures[i].texture, index: fragmentTextures[i].index)
      }

      // added this for Vertex functions
      renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: uniformId)
      renderEncoder.setVertexBuffer(initializationBuffer, offset: 0, index: kbuffId)


      self.finishCommandEncoding(renderEncoder)

      renderEncoder.endEncoding()
    }
  }




}
