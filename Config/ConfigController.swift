
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
#if os(macOS)
import AppKit
#endif

import MetalKit
import os
import SwiftUI

protocol VideoStream {
  func readBuffer(_ nVSync : TimeInterval) -> MTLTexture?
}

/** This class processes the initializer and sets up the shader parameters based on the shader defaults and user defaults */
struct TextureParameter : Identifiable {
  typealias ObjectIdentifier = Int
  var id : ObjectIdentifier

  var index : Int
  var type : MTLTextureType
  var access : MTLArgumentAccess
  var data : MTLDataType
  var image : XImage
  var video : VideoStream?
  var texture : MTLTexture?

  init?(_ a : MTLArgument, id: Int) {
    self.id = id
    if a.type == .texture {
      index = a.index
      type = a.textureType
      access = a.access
      data = a.textureDataType
      image = XImage.init(named: ["london", "flagstones", "water", "wood", "still_life"][a.index % 5] )!
    } else {
      return nil
    }
  }
}

/*
public class ConfigController {

  /// This buffer is known as in on the metal side
  public var initializationBuffer : MTLBuffer!
  /// This is the CPU overlay on the initialization buffer
  var inbuf : MyMTLStruct!

  /// this is the clear color for alpha blending?
  var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )

  /* private */ var cached : [IdentifiableView]?
  //  private var renderManager : RenderManager

  var pipelinePasses : [RenderPipelinePass] = []
  var fragmentTextures : [TextureParameter] = []

  /* private */ var myOptions : MyMTLStruct!
  /* private  */ var dynPref : DynamicPreferences? // need to hold on to this for the callback
  /* internal */ /* private */ var shaderName : String
  private var computeBuffer : MTLBuffer?

  //  var videoNames : [VideoSupport] = []
  var webcam : WebcamSupport?

  var uniformBuffer : MTLBuffer?

  /** This sets up the initializer by finding the function in the shader,
   using reflection to analyze the types of the argument
   then setting up the buffer which will be the "preferences" buffer.
   It would be the "Uniform" buffer, but that one is fixed, whereas this one is variable -- so it's
   just easier to make it a separate buffer
   */
  required init(_ x : String) {
    shaderName = x
//    empty = XImage(named: "BrokenImage")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    // textureThumbnail = Array(repeating: nil, count: numberOfTextures)
    // inputTexture = Array(repeating: nil, count: Shader.numberOfTextures)

    // doInitialization()
  }

  func buildImageWells() -> [IdentifiableView] {
    var res = [IdentifiableView]()
    let a = ImageStrip(texes: Binding.init(get: { return self.fragmentTextures } , set: { self.fragmentTextures = $0 }))
    res.append( IdentifiableView(id: "imageStrip", view: AnyView(a)))
    return res
  }

  // this is getting called during onTapGesture in LibraryView -- when I'm launching the ShaderView
  func buildPrefView() -> [IdentifiableView] {
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
  
  func getClearColor(_ bst : MyMTLStruct) {
    guard let bb = bst["clearColor"] else { return }
    let v : SIMD4<Float> = bb.getValue()
    self.clearColor = v
  }

  func processWebcam(_ bst : MyMTLStruct ) {
   if let _ = bst["webcam"] {
   webcam = WebcamSupport()
   }
   }

  /*
   func purge() {
   _videoNames.forEach {
   $0.endProcessing()
   }
   _videoNames = []
   }
   */
  
  func processArguments(_ bst : MyMTLStruct ) {

    myOptions = bst
    
    for bstm in myOptions.children {
      let dnam = "\(self.shaderName).\(bstm.name!)"
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
  
  /*  func processVideos(_  bst: MyMTLStruct ) {
   _videoNames = []
   if let bss = bst.getStructArray("videos") {
   for bb in bss {
   if let jj = bb.getString(),
   let ii = Bundle.main.url(forResource: jj, withExtension: nil, subdirectory: "videos") {
   // print("appending \(jj) for \(self.shaderName ?? "" )")
   _videoNames.append( VideoSupport( ii ) )
   }
   }
   }
   }
   */

  func processTextures(_ bst : [MTLArgument] ) {
    for a in bst {
      if let b = TextureParameter(a, id: fragmentTextures.count) {
        fragmentTextures.append(b)
      }
    }
  }
  
  func segmented( _ t:String, _ items : [MyMTLStruct]) {
    let iv = UserDefaults.standard.integer(forKey: "\(self.shaderName).\(t)")
    setPickS(iv, items)
  }
  
  // FIXME: this is a duplicate of the one in DynamicPreferences
  func setPickS(_ a : Int, _ items : [MyMTLStruct] ) {
    for (i, tt) in items.enumerated() {
      tt.setValue(i == a ? 1 : 0 )
    }
  }
  
  func boolean(_ arg : MyMTLStruct) {
    arg.setValue( UserDefaults.standard.bool(forKey: "\(self.shaderName).\(arg.name!)") )
  }
  
  func colorPicker(_ arg : MyMTLStruct) {
    if let iv = UserDefaults.standard.color(forKey: "\(self.shaderName).\(arg.name!)") {
      arg.setValue(iv.asFloat4())
    }
  }
  
  func numberSliderInt(_ arg : MyMTLStruct) {
    let iv = UserDefaults.standard.integer(forKey: "\(self.shaderName).\(arg.name!)")
    // note the ".y"
    if var z : SIMD3<Int32> = arg.value as? SIMD3<Int32> {
      z.y = Int32(iv)
      arg.setValue(z)
    }
  }
  
  func numberSliderFloat(_ arg : MyMTLStruct) {
    let iv = UserDefaults.standard.float(forKey: "\(self.shaderName).\(arg.name!)")
    // note the ".y"
    if var z : SIMD3<Float> = arg.value as? SIMD3<Float> {
      z.y = iv
      arg.setValue(z)
    }
  }


  func justInitialization() async {
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

  /** this calls the GPU initialization routine to get the initial default values
   Take the contents of the buffer and save them as UserDefaults
   If the UserDefaults were previously set, ignore the results of the GPU initialization.

   This should only be called once at the beginning of the render -- when the view is loaded
   */
  func doInitialization( ) async {

    let uniformSize : Int = MemoryLayout<Uniform>.stride
    let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
    uni.label = "uniform"
    uniformBuffer = uni

    await justInitialization()


    await setupPipelines()

    if let a = (pipelinePasses[0] as? RenderPipelinePass)?.metadata.fragmentArguments {
      processTextures(a)
    }
    getClearColor(inbuf)
  }

  func resetTarget() {
    pipelinePasses = []
    fragmentTextures = []
  }

  func setupPipelines() async {
    pipelinePasses = []


    fragmentTextures = []

    if let vertexProgram = await currentVertexFn(""),
       let fragmentProgram = await currentFragmentFn(""),
       let p = RenderPipelinePass(
        label: "\(shaderName)",
        viCount: (4, 1),
        flags: 0,
        //          canvasSize: canvasSize,
        topology: .triangleStrip,
        computeBuffer : nil,
        functions: (vertexProgram, fragmentProgram)
       ) {
      pipelinePasses.append(p)
      // FIXME: put me back?
      // lastRender = p.resolveTextures.1
    } else {
      os_log("failed to create render pipeline pass for %s", type:.error, shaderName)
      return
    }
  }
  
  private func currentVertexFn(_ sfx : String) async -> MTLFunction? {
    let lun = "\(shaderName)___\(sfx)___Vertex"
    if let z = await function.find(lun) { return z }
    return await function.find("flatVertexFn")!
  }

  private func currentFragmentFn(_ sfx : String) async -> MTLFunction? {
    let lun = "\(shaderName)___\(sfx)___Fragment"
    if let z = await function.find(lun) { return z }
    return await function.find("passthruFragmentFn")!
  }
}

*/
