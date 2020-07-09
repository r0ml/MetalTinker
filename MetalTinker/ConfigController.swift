
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import AppKit
import MetalKit
import os

/** This class processes the initializer and sets up the shader parameters based on the shader defaults and user defaults */

public class ConfigController {

  /// This buffer is known as kbuff on the metal side
  var initializationBuffer : MTLBuffer!
  /// This is the CPU overlay on the initialization buffer
  private var kbuff : MyMTLStruct!

  /// this is the clear color for alpha blending?
  var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )

  private var cached : [IdentifiableView]?
  private var renderManager : RenderManager

  var pipelinePasses : [PipelinePass] = []
  
  private var myOptions : MyMTLStruct!
  private var dynPref : DynamicPreferences? // need to hold on to this for the callback
  private var shaderName : String
  private var configQ = DispatchQueue(label: "config q")
  private var computeBuffer : MTLBuffer?
  private var empty : CGImage

  /** This sets up the initializer by finding the function in the shader,
   using reflection to analyze the types of the argument
   then setting up the buffer which will be the "preferences" buffer.
   It would be the "Uniform" buffer, but that one is fixed, whereas this one is variable -- so it's
   just easier to make it a separate buffer
   */
  init(_ x : String, _ rm : RenderManager) {
    shaderName = x
    renderManager = rm
    empty = NSImage(named: "BrokenImage")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    // textureThumbnail = Array(repeating: nil, count: numberOfTextures)
  }
  
  // this is getting called during onTapGesture in LibraryView -- when I'm launching the ShaderView
  func buildPrefView() -> [IdentifiableView] {
    if let z = cached { return z }
    if let mo = myOptions {
      let a = DynamicPreferences.init(shaderName, self)
      dynPref = a
      cached = a.buildOptionsPane(mo)
      return cached!
    }
    return []
  }
  
  func getClearColor(_ bst : MyMTLStruct) {
    guard let bb = bst["clearColor"] else { return }
    let v : SIMD4<Float> = bb.getValue()
    self.clearColor = v
  }
  
  func processOptions(_ bst : MyMTLStruct ) {
    guard let mo = bst["options"] else {
      return
    }
    myOptions = mo
    
    for bstm in myOptions.children {
      let dnam = "\(self.shaderName).\(bstm.name!)"
      // if this key already has a value, ignore the initialization value
      let dd =  UserDefaults.standard.object(forKey: dnam)
      
      if let _ = bstm.structure {
        let ddm = bstm.children
        self.segmented(bstm.name, ddm)
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

  private var textureLoader = MTKTextureLoader(device: device)
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

  /** this calls the GPU initialization routine to get the initial default values
   Take the contents of the buffer and save them as UserDefaults
   If the UserDefaults were previously set, ignore the results of the GPU initialization.

   This should only be called once at the beginning of the render -- when the view is loaded
   */
  func doInitialization( _ live : Bool, config : ConfigController, size canvasSize : CGSize ) -> MTLBuffer? {

    let nam = shaderName + "InitializeOptions"
    guard let initializationProgram = findFunction( nam ) else {
      print("no initialization program for \(self.shaderName)")
      return nil
    }
    let cpld = MTLComputePipelineDescriptor()
    cpld.computeFunction = initializationProgram

    let commandBuffer = commandQueue.makeCommandBuffer()!
    commandBuffer.label = "Initialize command buffer for \(self.shaderName) "

    let uniformSize : Int = MemoryLayout<Uniform>.stride
    let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
    uni.label = "uniform"

    var cpr : MTLComputePipelineReflection?
    do {
      let initializePipelineState = try device.makeComputePipelineState(function: initializationProgram,
                                                                        options:[.argumentInfo, .bufferTypeInfo], reflection: &cpr)

      if let gg = cpr?.arguments.first(where: { $0.name == "kbuff" }),
        let ib = device.makeBuffer(length: gg.bufferDataSize, options: [.storageModeShared ]) {
        ib.label = "defaults buffer for \(self.shaderName)"
        ib.contents().storeBytes(of: 0, as: Int.self)
        initializationBuffer = ib
      } else if let ib = device.makeBuffer(length: 8, options: [.storageModeShared]) {
        ib.label = "empty kernel compute buffer for \(self.shaderName)"
        initializationBuffer = ib
      } else {
        os_log("failed to allocate initialization MTLBuffer", type: .fault)
        return uni
      }

      if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
        computeEncoder.label = "initialization and defaults encoder \(self.shaderName)"
        computeEncoder.setComputePipelineState(initializePipelineState)
        computeEncoder.setBuffer(uni, offset: 0, index: uniformId)
        computeEncoder.setBuffer(initializationBuffer, offset: 0, index: kbuffId)
        let ms = MTLSize(width: 1, height: 1, depth: 1);
        computeEncoder.dispatchThreadgroups(ms, threadsPerThreadgroup: ms);
        computeEncoder.endEncoding()
      }
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted() // I need these values to proceed
    } catch {
      os_log("%s", type:.fault, "failed to initialize pipeline state for \(shaderName): \(error)")
      return nil
    }

    // at this point, the initialization (preferences) buffer has been set
    if let gg = cpr?.arguments.first(where: { $0.name == "kbuff" }) {
      kbuff = MyMTLStruct.init(initializationBuffer, gg)
      processOptions(kbuff)
      getClearColor(kbuff)
    }
    return uni
  }

  func resetTarget() {
    pipelinePasses = []
  }

  func setupPipelines(size canvasSize : CGSize) {
    pipelinePasses = []
    var lastRender : MTLTexture?
    if let f = findFunction("\(shaderName)______Kernel"),
      let p = ComputePipelinePass(
        label: "frame initialize compute in \(shaderName)",
        gridSize: (1, 1 ) ,
        flags: Int32(0),
        function: f) {
      self.computeBuffer = p.computeBuffer
      pipelinePasses.append(p)
    }

    if let j = kbuff["pipeline"] {
      let jc = j.children
      for  (xx, mm) in jc.enumerated() {
        let sfx = mm

        // HERE is where I can also figure out blend mode and clear mode (from the fourth int32)

        // a bool (int?) datatype is a filter pass
 // FIXME: put me back for FILTER pipeline
        /*
 if  mm.datatype == .int {
          // presuming that this is a pipeline which involves calling a different (named) shader.

          
          // it cannot be a generalized shader.  It needs to be a fragment shader which takes a texture in and produces a texture out
          if let f = findFunction("\(mm.name!)___Filter"),
            let l = lastRender ?? inputTexture[0],
            let p = FilterPipelinePass(
              label: "\(sfx.name!) in \(shaderName)",
              size: canvasSize,
              flags: 0,
              function:f,
              input: l,
              isFinal: xx == jc.count - 1) {
            pipelinePasses.append(p)
            lastRender = p.texture // output from the filter pass
          } else {
            os_log("failed to create filter pipeline pass for %s", type: .error, String("\(sfx.name!) in \(shaderName)"))
          }
          // an int datatype is a blit pass -- it will blit copy n textures
          // in order to do so, it will create n pairs of textures, which will be set up
          // as render pass inputs for the next render pass
          //        } else if mm.datatype == .int {
          //          let pms : Int32 = mm.getValue()



        } else {
*/

          // the compute pipeline
          let pms : SIMD4<Int32> = mm.getValue()
          if (pms[0] == -1 ) {
            if let f = findFunction("\(shaderName)___\(sfx.name!)___Kernel"),
              let p = ComputePipelinePass(
                label: "\(sfx.name!) in \(shaderName)",
                gridSize: (Int(pms[1]), Int(pms[2])) ,
                flags: pms[3],
                function: f) {
              self.computeBuffer = p.computeBuffer
              pipelinePasses.append(p)
            }
          } else {
            if let vertexProgram = currentVertexFn(sfx.name),
              let fragmentProgram = currentFragmentFn(sfx.name),
              let ptc = MTLPrimitiveType.init(rawValue: UInt(pms[0])),
              let p = RenderPipelinePass(
                label: "\(sfx.name!) in \(shaderName)",
                viCount: (Int(pms[1]), Int(pms[2])),
                flags: pms[3],
                canvasSize: canvasSize,
                topology: ptc,
                computeBuffer : self.computeBuffer,
                functions: (vertexProgram, fragmentProgram)
                ) {

              // At this juncture, I must insert the blitter
              /*    let bce = commandBuffer.makeBlitCommandEncoder()!
               for i in 0..<numberOfRenderPasses {
               if let a = renderPassOutputs[i],
               let b = renderPassInputs[i] {
               bce.copy(from: a, to: b)
               }
               }
               bce.endEncoding()
               */


              //              let b = BlitRenderPass(
              //                label: "blit \(sfx.name!) in \(shaderName)",
              //                pairs:
              //              )
              //              pipelinePasses.append(b)

              pipelinePasses.append(p)
              // FIXME: put me back?
              // lastRender = p.resolveTextures.1
            } else {
              os_log("failed to create render pipeline pass for %s in %s", type:.error, sfx.name!, shaderName)
              return
            }
          }
        }
//      }
    } else {
      if let vertexProgram = currentVertexFn(""),
        let fragmentProgram = currentFragmentFn(""),
        let p = RenderPipelinePass(
          label: "\(shaderName)",
          viCount: (4, 1),
          flags: 0,
          canvasSize: canvasSize,
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
  }

  private func currentVertexFn(_ sfx : String) -> MTLFunction? {
    let lun = "\(shaderName)___\(sfx)___Vertex";
    return findFunction(lun) ?? findFunction("flatVertexFn");
  }

  private func currentFragmentFn(_ sfx : String) -> MTLFunction? {
    let lun = "\(shaderName)___\(sfx)___Fragment";
    return findFunction(lun) ?? findFunction("passthruFragmentFn")
  }
}

