
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import SwiftUI
import os

class ConfigControllerFilter : ConfigController {

 // var pipeline : RenderPipelinePass!
  
  required init(_ x : String) {
    print("filter subclass \(x)")
    super.init(x)
//    empty = XImage(named: "BrokenImage")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    // textureThumbnail = Array(repeating: nil, count: numberOfTextures)
    // inputTexture = Array(repeating: nil, count: Shader.numberOfTextures)

    // doInitialization()
  }

  // this is getting called during onTapGesture in LibraryView -- when I'm launching the ShaderView
  override func buildPrefView() -> [IdentifiableView] {
    if let z = cached { return z }
    if let mo = myOptions {
      let a = DynamicPreferences.init(shaderName)
      dynPref = a
      let c = buildImageWells()
      let d = IdentifiableView(id: "sources", view: AnyView(SourceStrip()))

      cached = [d] + c + a.buildOptionsPane(mo)
      return cached!
    }
    return []
  }
  
  
  override func doInitialization( ) async {

    let uniformSize : Int = MemoryLayout<Uniform>.stride
    let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
    uni.label = "uniform"
    uniformBuffer = uni

    await justInitialization()


 //   await setupPipelines()

/* if let a = pipelineState.metadata.fragmentArguments {
      processTextures(a)
    }
 */
    getClearColor(inbuf)
  }

  
  
  override func justInitialization() async {
    // await super.justInitialization()
    let nam = shaderName + "InitializeOptions"
    guard let initializationProgram = await function.find( nam ) else {
      print("no initialization program for \(self.shaderName)")
      return
    }
    let cpld = MTLComputePipelineDescriptor()
    cpld.computeFunction = initializationProgram

    let commandBuffer = commandQueue.makeCommandBuffer()!
    commandBuffer.label = "Initialize command buffer for \(self.shaderName) "


    var cpr : MTLComputePipelineReflection?
    do {
      let initializePipelineState = try device.makeComputePipelineState(function: initializationProgram,
                                                                        options:[.argumentInfo, .bufferTypeInfo], reflection: &cpr)


      // FIXME: I want the render pipeline metadata

      if let gg = cpr?.arguments.first(where: { $0.name == "in" }),
         let ib = device.makeBuffer(length: gg.bufferDataSize, options: [.storageModeShared ]) {
        ib.label = "defaults buffer for \(self.shaderName)"
        ib.contents().storeBytes(of: 0, as: Int.self)
        initializationBuffer = ib
      } else if let ib = device.makeBuffer(length: 8, options: [.storageModeShared]) {
        ib.label = "empty kernel compute buffer for \(self.shaderName)"
        initializationBuffer = ib
      } else {
        os_log("failed to allocate initialization MTLBuffer", type: .fault)
        return
      }

      if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
        computeEncoder.label = "initialization and defaults encoder \(self.shaderName)"
        computeEncoder.setComputePipelineState(initializePipelineState)
//        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
        computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)

        let ms = MTLSize(width: 1, height: 1, depth: 1);
        computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
        computeEncoder.endEncoding()
      }
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed
    } catch {
      os_log("%s", type:.fault, "failed to initialize pipeline state for \(shaderName): \(error)")
      return
    }

    // at this point, the initialization (preferences) buffer has been set
    if let gg = cpr?.arguments.first(where: { $0.name == "in" }) {
      inbuf = MyMTLStruct.init(initializationBuffer, gg)
      processArguments(inbuf)
    }

    
    
    
    
    
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
}
