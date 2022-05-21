// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit
import MetalKit
import SwiftUI
import os


class FragmentScene : T1SCNScene {
  override var group : String { get { self.library } }
  var shaderName : String
  var library : String
//  var config : ConfigController
  var touchLoc : CGPoint?
  var startDragLoc : CGPoint?

  required init(shader: String, library: String) {
    self.shaderName = shader
    self.library = library
//    self.config = ConfigControllerT3SCN(shader)

    let j = SCNMaterial( )

    var ttt = Times()
    let planeSize = CGSize(width: 16, height: 9)


    super.init()

    //    let cd = tan(myCameraNode.camera!.fieldOfView * CGFloat.pi / 180.0) * (myCameraNode.camera!.projectionDirection == .vertical ? planeSize.height : planeSize.width) / 2.0
    //    myCameraNode.position = SCNVector3(0, 0, cd )

    let p = SCNProgram()

    p.fragmentFunctionName = self.shaderName + "______Fragment"
    p.vertexFunctionName = "vertex_function"

    // FIXME: this is broken -- need to split out the SceneKit shaders
    p.library = functionMaps["Generators"]!.libs.first(where: {$0.label == self.library })!

//    Task {
      justInitialization()
//    }

    // FIXME:
    // I could also use key-value coding on an nsdata object
    // on geometry or material call  setValue: forKey: "uni"

    // Bind the name of the fragment function parameters to the program.
    p.handleBinding(ofBufferNamed: "uni",
                    frequency: .perFrame,
                    handler: {
      (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
      //                           let s = renderer.currentViewport.size
      let s = planeSize
      ttt.currentTime = now()

      var u = self.setupUniform(size: CGSize(width: s.width * 10.0, height: s.height * 10), times: ttt)
      buffer.writeBytes(&u, count: MemoryLayout<Uniform>.stride)

    })

    /*    p.handleBinding(ofBufferNamed: "in",
     frequency: .perFrame,
     handler: {
     (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
     if let ib = self.config.initializationBuffer {
     buffer.writeBytes(ib.contents(), count: ib.length)
     } else {
     var zero = 0
     buffer.writeBytes(&zero, count: MemoryLayout<Double>.stride)
     }
     })
     */

    j.program = p
    j.isDoubleSided = true

    let im = XImage.init(named: "london")!
    let matprop = SCNMaterialProperty.init(contents: im)
    j.setValue(matprop, forKey: "tex")
    j.setValue(initializationBuffer, forKey: "in")

    // Why does the size not matter here???
    let g = SCNPlane(width: planeSize.width, height: planeSize.height)
    g.materials = [j]
    let gn = SCNNode(geometry: g)
    gn.name = "Shader plane node"

    // I could set the background to a CAMetalLayer and then render into it.....

    //    let target = SCNLookAtConstraint(target: gn)
    //    target.isGimbalLockEnabled = true
    //    myCameraNode.constraints = [target]


    //    self.dist = cd

    self.rootNode.addChildNode(gn)
    self.background.contents = XColor.orange
    self.isPaused = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  required init() {
    fatalError("init() has not been implemented")
  }


  var iFrame : Int = 0

  func setupUniform( size: CGSize /* , scale : Int, */ /* uniform uni: MTLBuffer */ , times : Times ) -> Uniform {

    var uniform = Uniform()

    iFrame += 1

#if os(macOS)
    let modifierFlags = XEvent.modifierFlags
    let mouseButtons = XEvent.pressedMouseButtons
#endif

    //   let mouseButtons = NSEvent.pressedMouseButtons

    // let w = Float(size.width)
    // let h = Float(size.height)
    // let s = Float(scale)

    // ==================================================
    // These are zapped out
    // not sure in SceneKit how to map the location of a touch onto the Node which is being rendered here.
    uniform.iMouse    = SIMD2<Float>(repeating: 0.5) //       SIMD2<Float>( s * Float(mouseLoc.x)  / w, 1 - s * Float(mouseLoc.y) / h )
    uniform.lastTouch = SIMD2<Float>(repeating: 0.5) //       SIMD2<Float>( s * Float(lastTouch.x) / w, 1 - s * Float(lastTouch.y) / h );

    if let hl = touchLoc, let ohl = startDragLoc {
      uniform.iMouse = SIMD2<Float>(x: Float(hl.x), y: Float(hl.y) )
      uniform.lastTouch = SIMD2<Float>(x: Float(ohl.x), y: Float(ohl.y) )
    }

#if os(macOS)
    uniform.mouseButtons = Int32(mouseButtons)
    uniform.eventModifiers = Int32(modifierFlags.rawValue)
#endif

    // ==================================================

    // ==================================================
    // for now, this too is zpped out until I figure out how to deal with keyPresses
    // Pass the key event in to the shader, then reset (so it only gets passed once)
    // when the key is released, event handling will so indicate.
    uniform.keyPress = SIMD2<UInt32>(repeating: 0) // self.keyPress
    // self.keyPress.x = 0;
    // ==================================================

    // set resolution and time
    uniform.iFrame = Int32(iFrame)
    uniform.iResolution = SIMD2<Float>(Float(size.width), Float(size.height)) * 10
    uniform.iTime = Float(times.currentTime - times.startTime)
    uniform.iTimeDelta = Float(times.currentTime - times.lastTime)

    // Set up iDate
    let _date = Date()
    let components = Calendar.current.dateComponents( Set<Calendar.Component>([.year, .month, .day, .hour, .minute,  .second]), from:_date)
    let d = components.second! + components.minute! * 60 + components.hour! * 3600;
    let d2 = Float(d) + Float(_date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1));
    if let y = components.year, let m = components.month, let d = components.day {
      uniform.iDate = SIMD4<Float>(Float(y), Float(m), Float(d), d2)
    }

    // Done.  Sync with GPU
    //    uni.didModifyRange(0..<uni.length)
    return uniform
  }



  func convertToScenOf(point: CGPoint, bounds: CGRect) -> SCNVector3{

    // assuming that the fieldOfView is vertical

#if os(macOS)
    let ss = NSScreen.main?.frame.size ?? CGSize(width: 16, height: 9)
#else
    let ss = UIScreen.main.currentMode?.size ?? CGSize(width: 16, height: 9)
#endif

    //    print(ss)
    let mp = point - bounds.size / 2.0
    var y = tan(myCameraNode.camera!.fieldOfView / 180 / 2 * CGFloat.pi) * Double(myCameraNode.position.z)
    var x = y * ss.width / ss.height

    let adjb = CGSize(width: bounds.size.height * ss.width / ss.height, height: bounds.size.height)
    //    print(adjb)

    if myCameraNode.camera!.projectionDirection == .vertical {

    } else {
      let z = x
      x = y
      y = z
    }

    let xx = XFloat(mp.x * x * 2 / adjb.width)
    let yy = XFloat(mp.y * y * 2 / adjb.height)


    let d = rootNode.childNodes[0].position.z

    let target = SCNVector3(x: xx, y: yy, z: d - 0.01 )
    return target
    /*
     let Z_Far:CGFloat = 0.1
     var Screen_Aspect : CGFloat = 0; // 0.3; // UIScreen.main.bounds.size.width > 400 ? 0.3 : 0.0
     // Calculate the distance from the edge of the screen
     let Y = tan(myCamera.fieldOfView/180/2 * CGFloat.pi) * Z_Far-Screen_Aspect
     let X = tan(myCamera.fieldOfView/2/180 * CGFloat.pi) * Z_Far-Screen_Aspect * bounds.size.width/bounds.size.height
     let alphaX = 2 *  CGFloat(X) / bounds.size.width
     let alphaY = 2 *  CGFloat(Y) / bounds.size.height
     let x = -CGFloat(X) + point.x * alphaX
     let y = CGFloat(Y) - point.y * alphaY
     let target = SCNVector3Make(x, y, -Z_Far)
     return target
     //    return myCameraNode.convertPosition(target, to: rootNode)
     */
  }

  func hiTest(point : CGPoint, bounds : CGRect) -> CGPoint? {
    let a = convertToScenOf(point: point, bounds: CGRect(origin: .zero, size: bounds.size))
    let b = myCameraNode.position
    var hto = [String: Any]()
    hto[SCNHitTestOption.searchMode.rawValue] = SCNHitTestSearchMode.all.rawValue
    let k = self.rootNode.hitTestWithSegment(from: b, to: a, options: hto)

    //   print(k)
    let res = k.first?.textureCoordinates(withMappingChannel: 0)
    return res
    // return k.first
  }



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
  /* internal */ /* private */ // var shaderName : String
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
      // let d = IdentifiableView(id: "sources", view: AnyView(SourceStrip()))

      cached = c + a.buildOptionsPane(mo)
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
     webcam = WebcamSupport(camera: "FIXME:")
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
      if let b = TextureParameter(a, 0, getTexture(fragmentTextures.count), textureKey(fragmentTextures.count), id: fragmentTextures.count) {
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
    let nam = shaderName + "_InitializeOptions"
    guard let initializationProgram = functionMaps["SceneShaders"]!.find( nam ) else {
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

#if os(macOS) || targetEnvironment(macCatalyst)
let uni = device.makeBuffer(length: uniformSize, options: [.storageModeManaged])!
#else
let uni = device.makeBuffer(length: uniformSize, options: [])!
#endif

    uni.label = "uniform"
    uniformBuffer = uni

    justInitialization()


    await setupPipelines()

    if let a = pipelinePasses[0].metadata.fragmentArguments {
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
    let lun = "\(shaderName)___\(sfx)___Vertex"
    if let z = functionMaps["Shaders"]!.find(lun) { return z }
    return functionMaps["Shaders"]!.find("flatVertexFn")!
  }

  private func currentFragmentFn(_ sfx : String) -> MTLFunction? {
    let lun = "\(shaderName)___\(sfx)___Fragment"
    if let z = functionMaps["Shaders"]!.find(lun) { return z }
    return functionMaps["Shaders"]!.find("passthruFragmentFn")!
  }

  func textureKey(_ z : Int) -> String {
    return "\(self.shaderName).texture.\(z)"
  }

  func getTexture(_ z : Int) -> XImage {
    if let z = UserDefaults.standard.data(forKey: textureKey(z) ) {
      var isStale = false
      if let bmu = try? URL(resolvingBookmarkData: z, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
        if (!isStale) {
          if bmu.startAccessingSecurityScopedResource() {
            defer { bmu.stopAccessingSecurityScopedResource() }
            if let i = XImage.init(contentsOf: bmu) {
              return i
            }
          }
        }
      }
    }
    return XImage.init(named: ["london", "flagstones", "water", "wood", "still_life"][z % 5] )!

  }




}

