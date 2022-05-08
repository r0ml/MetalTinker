
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

class ParameterizedShader : GenericShader {

  /// This is the CPU overlay on the initialization buffer
  var inbuf : MyMTLStruct!
  var initializationBuffer : MTLBuffer!

  var cached : [IdentifiableView]?

  var myOptions : MyMTLStruct!
  var dynPref : DynamicPreferences? // need to hold on to this for the callback

  var initializeReflection : MTLComputePipelineReflection?
  var initializePipelineState : MTLComputePipelineState?

  override var myGroup : String {
    get { "Parameterized" }
  }


  required init(_ s : String ) {
    super.init(s)
  }

  override func justInitialization() {
    // await super.justInitialization()

    var ibl = 8
    if let aa = (self.metadata.fragmentArguments?.filter { $0.name == "in" })?.first {
      ibl = aa.bufferDataSize
    } else if let bb = (self.metadata.vertexArguments?.filter { $0.name == "in" })?.first {
      ibl = bb.bufferDataSize
    }
    if ibl == 0 { ibl = 8 }

    if let ib = device.makeBuffer(length: ibl, options: [.storageModeShared ]) {
      ib.label = "defaults buffer for \(self.myName)"
      ib.contents().storeBytes(of: 0, as: Int.self)
      self.initializationBuffer = ib
    }

    let nam = myName + "_InitializeOptions"
    guard let initializationProgram = functionMaps[self.myGroup]!.find( nam ) else {
      return
    }
    let cpld = MTLComputePipelineDescriptor()
    cpld.computeFunction = initializationProgram



    do {
      initializePipelineState = try device.makeComputePipelineState(function: initializationProgram,
                                                                    options:[.argumentInfo, .bufferTypeInfo], reflection: &initializeReflection)
    } catch {
      os_log("%s", type:.fault, "failed to initialize pipeline state for \(myName): \(error)")
      return
    }
  }

  func processArguments(_ bst : MyMTLStruct ) {

    myOptions = bst

//    if myName == "Buffer_computed_points" {
//      print("hah")
//    }

    for bstm in myOptions.children {
      let dnam = "\(self.myName).\(bstm.name!)"
      // if this key already has a value, ignore the initialization value
      let dd =  UserDefaults.standard.object(forKey: dnam)

      if let _ = bstm.structure {
        let ddm = bstm.children
        if let kk = bstm.children.first?.datatype, kk == .int {
          self.segmented(bstm.name, ddm)
        }
        // self.dropDown(bstm.name, ddm) } }

      } else {

        let dat = bstm.value
        switch dat {
        case is Bool:
          let v = dat as! Bool
          UserDefaults.standard.set(dd ?? v, forKey: dnam)
          self.boolean(bstm);

        case is SIMD4<Float>:
          let v = dat as! SIMD4<Float>
          UserDefaults.standard.set(dd ?? v.y, forKey: dnam)
          self.colorPicker( bstm)

        case is SIMD3<Float>:
          let v = dat as! SIMD3<Float>
          UserDefaults.standard.set(dd ?? v.y, forKey: dnam)
          self.numberSliderFloat( bstm )

        case is SIMD3<Int32>:
          let v = dat as! SIMD3<Int32>
          UserDefaults.standard.set(dd ?? v.y, forKey: dnam)
          self.numberSliderInt( bstm )

        default:
          os_log("%s", type:.error, "\(bstm.name!) is \(bstm.datatype)")
        }
      }
    }
  }



  func segmented( _ t:String, _ items : [MyMTLStruct]) {
    let iv = UserDefaults.standard.integer(forKey: "\(self.myName).\(t)")
    setPickS(iv, items)
  }

  // FIXME: this is a duplicate of the one in DynamicPreferences
  func setPickS(_ a : Int, _ items : [MyMTLStruct] ) {
    for (i, tt) in items.enumerated() {
      tt.setValue(i == a ? 1 : 0 )
    }
  }

  func boolean(_ arg : MyMTLStruct) {
    arg.setValue( UserDefaults.standard.bool(forKey: "\(self.myName).\(arg.name!)") )
  }

  func colorPicker(_ arg : MyMTLStruct) {
    if let iv = UserDefaults.standard.color(forKey: "\(self.myName).\(arg.name!)") {
      arg.setValue(iv.asFloat4())
    }
  }

  func numberSliderInt(_ arg : MyMTLStruct) {
    let iv = UserDefaults.standard.integer(forKey: "\(self.myName).\(arg.name!)")
    // note the ".y"
    if var z : SIMD3<Int32> = arg.value as? SIMD3<Int32> {
      z.y = Int32(iv)
      arg.setValue(z)
    }
  }

  func numberSliderFloat(_ arg : MyMTLStruct) {
    let iv = UserDefaults.standard.float(forKey: "\(self.myName).\(arg.name!)")
    // note the ".y"
    if var z : SIMD3<Float> = arg.value as? SIMD3<Float> {
      z.y = iv
      arg.setValue(z)
    }
  }



  // FIXME: do I need this?
  func getClearColor(_ bst : MyMTLStruct) {
    guard let bb = bst["clearColor"] else { return }
    let v : SIMD4<Float> = bb.getValue()
    self.clearColor = v
  }



  // this is getting called during onTapGesture in LibraryView -- when I'm launching the ShaderView
  override func buildPrefView() -> [IdentifiableView] {
    beginShader()
    if let z = cached { return z }

    // I should move the creation of TextureParameters here



    if let mo = myOptions {
      let a = DynamicPreferences.init(myName)
      dynPref = a


      let jj = self.morePrefs()
      //      let c = ImageStrip(texes: Binding.init(get: { return self.fragmentTextures } , set: { self.fragmentTextures = $0 }))
      let k = jj + /* [IdentifiableView(id: "sources", view: AnyView(c))] + */ a.buildOptionsPane(mo)
      cached = k
      return k
    }
    return []
  }
  
  func morePrefs() -> [IdentifiableView] {
    return []
  }

  override func setArguments(_ renderEncoder : MTLRenderCommandEncoder) {
    renderEncoder.setFragmentBuffer(initializationBuffer, offset: 0, index: kbuffId)

    super.setArguments(renderEncoder)
  }

  override func setInitializationArguments( _ computeEncoder : MTLComputeCommandEncoder) {
    computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)

    super.setInitializationArguments(computeEncoder)
  }

  func beginShader() {
    //    print("start \(#function)")

    // should doInitialization go here?

    if let ips = initializePipelineState,
       let commandBuffer = commandQueue.makeCommandBuffer(),
       let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
      commandBuffer.label = "Initialize command buffer for \(self.myName) "
      computeEncoder.label = "initialization and defaults encoder \(self.myName)"
      computeEncoder.setComputePipelineState(ips)
      //        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: uniformId)
      computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)

      let ms = MTLSize(width: 1, height: 1, depth: 1);
      computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
      computeEncoder.endEncoding()

      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed
    }
    if let gg = metadata.fragmentArguments?.first(where: {$0.name == "in" } ) {
        inbuf = MyMTLStruct.init(initializationBuffer, gg)
        processArguments(inbuf)

      getClearColor(inbuf)
    }
  }

}

