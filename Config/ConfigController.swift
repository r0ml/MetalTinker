
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import AppKit
import MetalKit
import os
import SwiftUI
import UniformTypeIdentifiers

protocol VideoStream {
  func readBuffer(_ nVSync : TimeInterval) -> MTLTexture?
}

/** This class processes the initializer and sets up the shader parameters based on the shader defaults and user defaults */


/*struct Clem : Identifiable {
 typealias ObjectIdentifier = Int
 var id: ObjectIdentifier
 var parm : TextureParameter

 init(_ t : (Int, TextureParameter) ) {
 id = t.0
 parm = t.1
 }

 }*/

struct TextureParameter : Identifiable {
  typealias ObjectIdentifier = Int
  var id : ObjectIdentifier

  var index : Int
  var type : MTLTextureType
  var access : MTLArgumentAccess
  var data : MTLDataType
  var image : NSImage
  var video : VideoStream?
  var texture : MTLTexture?

  init?(_ a : MTLArgument, id: Int) {
    self.id = id
    if a.type == .texture {
      index = a.index
      type = a.textureType
      access = a.access
      data = a.textureDataType
      image = NSImage.init(named: ["london", "flagstones", "water", "wood", "still_life"][a.index % 5] )!
    } else {
      return nil
    }
  }
}
public class ConfigController {

  /// This buffer is known as in on the metal side
  var initializationBuffer : MTLBuffer!
  /// This is the CPU overlay on the initialization buffer
  private var inbuf : MyMTLStruct!

  /// this is the clear color for alpha blending?
  var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )

  private var cached : [IdentifiableView]?
  //  private var renderManager : RenderManager

  var pipelinePasses : [PipelinePass] = []
  var fragmentTextures : [TextureParameter] = []

  private var myOptions : MyMTLStruct!
  private var dynPref : DynamicPreferences? // need to hold on to this for the callback
  private var shaderName : String
  private var configQ = DispatchQueue(label: "config q")
  private var computeBuffer : MTLBuffer?
  private var empty : CGImage

  //  var videoNames : [VideoSupport] = []
  //  var webcam : WebcamSupport?

  var uniformBuffer : MTLBuffer?

  /** This sets up the initializer by finding the function in the shader,
   using reflection to analyze the types of the argument
   then setting up the buffer which will be the "preferences" buffer.
   It would be the "Uniform" buffer, but that one is fixed, whereas this one is variable -- so it's
   just easier to make it a separate buffer
   */
  init(_ x : String) {
    shaderName = x
    empty = NSImage(named: "BrokenImage")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
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
      let a = DynamicPreferences.init(shaderName, self)
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

  /* func processWebcam(_ bst : MyMTLStruct ) {
   if let _ = bst["webcam"] {
   webcam = WebcamSupport()
   }
   } */

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
        if bstm.name == "pipeline" { continue }
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

  private var textureLoader = MTKTextureLoader(device: device)

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


  func justInitialization() {
    let nam = shaderName + "InitializeOptions"
    guard let initializationProgram = findFunction( nam ) else {
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
  func doInitialization( /* _ live : Bool */ /*, config : ConfigController */  /*, size canvasSize : CGSize */ ) {

    let uniformSize : Int = MemoryLayout<Uniform>.stride
    let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
    uni.label = "uniform"
    uniformBuffer = uni

    justInitialization()


    setupPipelines()

    if let a = (pipelinePasses[0] as? RenderPipelinePass)?.metadata.fragmentArguments {
      processTextures(a)
    }
    getClearColor(inbuf)
  }

  func resetTarget() {
    pipelinePasses = []
    fragmentTextures = []
  }

  func setupPipelines() {
    pipelinePasses = []


    fragmentTextures = []
    //    var lastRender : MTLTexture?


    if let j = inbuf["pipeline"] {
      let jc = j.children
      for  (xx, mm) in jc.enumerated() {
        let sfx = mm.name!

        // HERE is where I can also figure out blend mode and clear mode (from the fourth int32)

        // the compute pipeline
        let pms : SIMD4<Int32> = mm.getValue()
        if (pms[0] == -1 ) {
          if let f = findFunction("\(shaderName)___\(sfx)___Kernel"),
             let p = ComputePipelinePass(
              label: "\(sfx) in \(shaderName)",
              //                pms: mm,
              viCount: (Int(pms[1]), Int(pms[2])) ,
              flags: pms[3],
              function: f) {
            self.computeBuffer = p.computeBuffer
            pipelinePasses.append(p)
          }
        } else {
          if let vertexProgram = currentVertexFn(sfx),
             let fragmentProgram = currentFragmentFn(sfx),
             let ptc = MTLPrimitiveType.init(rawValue: UInt(pms[0])),
             let p = RenderPipelinePass(
              label: "\(sfx) in \(shaderName)",
              // pms: mm,
              viCount: (Int(pms[1]), Int(pms[2])),
              flags: pms[3],
              // canvasSize: canvasSize,
              topology: ptc,
              computeBuffer : self.computeBuffer,
              functions: (vertexProgram, fragmentProgram)
             ) {

            pipelinePasses.append(p)
            // FIXME: put me back?
            // lastRender = p.resolveTextures.1
          } else {
            os_log("failed to create render pipeline pass for %s in %s", type:.error, sfx, shaderName)
            return
          }
        }
      }

      //      }
    } else {
      setupDefaultPipeline()
    }
  }

  func setupDefaultPipeline() {
    if let vertexProgram = currentVertexFn(""),
       let fragmentProgram = currentFragmentFn(""),
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


  private func currentVertexFn(_ sfx : String) -> MTLFunction? {
    let lun = "\(shaderName)___\(sfx)___Vertex";
    return findFunction(lun) ?? findFunction("flatVertexFn");
  }

  private func currentFragmentFn(_ sfx : String) -> MTLFunction? {
    let lun = "\(shaderName)___\(sfx)___Fragment";
    return findFunction(lun) ?? findFunction("passthruFragmentFn")
  }
}

/*class SourceProvider : NSObject, NSItemProviderWriting {
 var name : String

 init(_ n : String) {
 name = n
 }

 }*/

struct SourceStrip : View {

  var body: some View {
    let z = NSItemProvider(item: "webcam".data(using: .utf8)as NSSecureCoding?, typeIdentifier: UTType.plainText.identifier)

    return HStack {
      Image(systemName: "video.circle" ).onDrag {
        return z
      }
    }
  }
}

/*struct Clem : Identifiable {
 typealias ObjectIdentifier = Int
 var id: ObjectIdentifier
 var parm : TextureParameter

 init(_ t : (Int, TextureParameter) ) {
 id = t.0
 parm = t.1
 }

 }*/

struct ImageStrip : View {
  @Binding var texes : [TextureParameter]
  @State var uuid = UUID()

  var body : some View {
    HStack {
      ForEach(texes) { (jj) in

        // FIXME: i windws up out of range -- must be from resetting texes
        Image.init(nsImage: texes[jj.id].image).resizable().scaledToFit()
          .onDrop(of: [UTType.fileURL, UTType.plainText, UTType.image], isTargeted: nil, perform: { (y) in

            var res = false
            //          var sem = DispatchSemaphore(value: 0)

            //          DispatchQueue.global().async {
            /*          y[0].loadItem(forTypeIdentifier: UTType.image.identifier, options: nil ) {
             (im, error) in
             print(im)
             print(error)
             }

             */
            y[0].loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
              (data, error) in
              if let d = data {
                // I guess I should initialize the webcam here?
                // and also grab a thumbnail frame
                let z = WebcamSupport()
                z.startRunning()
                texes[jj.id].video = z // WebcamSupport()
              }
            }


            y[0].loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) {
              (urlData, error)  in
              //            defer {
              //              sem.signal()
              //            }
              if let e = error {
                print(e.localizedDescription)
                return
              }

              if let urlData = urlData as? Data {
                let j = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL

                // FIXME: Fix this on StackOverflow
                let uti = UTType.types(tag: j.pathExtension, tagClass: UTTagClass.filenameExtension, conformingTo: UTType.data)
                /*            let uti = UTTypeCreatePreferredIdentifierForTag(
                 kUTTagClassFilenameExtension,
                 j.pathExtension as CFString,
                 nil)
                 let utix = uti?.takeRetainedValue()
                 */
                if uti[0].conforms(to: UTType.image) {

                  if let k = NSImage.init(contentsOf: j) {
                    texes[jj.id].image = k
                    texes[jj.id].texture = k.getTexture(MTKTextureLoader(device: device))
                    uuid = UUID()
                    res = true
                  }
                } else if uti[0].conforms(to: .movie) {
                  let vs = VideoSupport(j)
                  texes[jj.id].video = vs
                  vs.getThumbnail {
                    texes[jj.id].image = NSImage.init(cgImage: $0, size: CGSize(width: $0.width, height: $0.height))
                  }
                  uuid = UUID()
                  res = true
                } else {

                  // fail
                  print("unknown file type dropped")
                }

              }
              return
            }
            //          }
            //          sem.wait()
            return true // res
          }).frame(width: 100, height: 100).border(Color.purple, width: 4)

      }
      Text(uuid.uuidString).hidden()
    }
  }
}
