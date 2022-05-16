// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import SceneKit
import os

struct ShaderNodeView<T : GenericShader> : View {
  @GestureState var magnifyBy : CGFloat = 1
  @GestureState var dragger : CGPoint = .zero

  @State var overImg = false
  @State var paused = false
  var shader : T
  var mouseLocation : NSPoint { NSEvent.mouseLocation }
  var theDelegate = MyDelegate()

  init(shader: T) {
    self.shader = shader
  }

  var mag : some Gesture {
    MagnificationGesture()
      .updating($magnifyBy)  {
        cs, gs, t in gs = cs
      }
      .onChanged { m in
        //        if let x = delegate.scene as? T3SCNScene {
        //          DispatchQueue.main.async { x.zoom(m) }
        //        }
      }
      .onEnded { g in
        //        if let x = delegate.scene as? T3SCNScene {
        //          DispatchQueue.main.async { x.updateZoom(g) }
        //        }
      }
  }

  var drag : some Gesture {
    DragGesture().updating($dragger) {
      cs, gs, t in gs = cs.location
      print("\(cs.location) from \(cs.startLocation) -- translation: \(cs.translation)")
    }
  }

  var body: some View {
    VStack {
      GeometryReader { g in
        let drag = DragGesture().updating($dragger) {
          cs, gs, t in gs = cs.location
          //    print("\(cs.location) from \(cs.startLocation) -- translation: \(cs.translation)")
          //       if let sc = delegate.scene as? T3ShaderSCNScene {
          //            let zz = sc.hiTest(point: cs.location, bounds: g.frame(in: .global))

          //    print("hitTest: \(zz)")
          //          sc.touchLoc = zz
          // FIXME: need this to be non-null, but it should be the result of hittesting the start location, not the current location
          //            sc.startDragLoc = zz
          //         }
        }
        //       let z = delegate.scene
        //       let _ = z.setSize(g.size)

        let kk = getScene()
        //        let _ = { kk.background.contents =  }()
        let z = shader
        let _ = Task {
          await z.setup.setSize(g.size)
        }

        let sv = SceneView(scene: kk,
                  options: paused ? [] : [ .allowsCameraControl, .rendersContinuously ],
                  //                      preferredFramesPerSecond: 120,
                  antialiasingMode: SCNAntialiasingMode.multisampling4X,
                  delegate: theDelegate
        )

        sv
        .gesture(mag)
        .gesture(drag)
        .onHover { over in
          overImg = over
        }
        .onAppear {
          //            print("addLocalMonitoring")
          NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved ]) { arg in
            //              if overImg {
            let zz = arg.locationInWindow
            let z = arg.cgEvent!.unflippedLocation

            let offs = NSApplication.shared.windows[0].frame


            //              if let b = arg.window?.screen?.backingScaleFactor {
            let bb : CGFloat = 1 // CGFloat(multisampleCount)
            let k = g.frame(in: .global)

            let q = offs.height - k.maxY



//            Task {

//              if (k.minX != 0) {
                let j = CGPoint(x: (zz.x - k.minX) / bb  , y: (zz.y - k.minY ) / bb  )

                let jj = CGPoint(x: (z.x - offs.minX - k.minX) / bb, y: (z.y - offs.minY - q /* k.minY */ ) / bb )

          //  print(j, jj)


            let fracx = jj.x / g.size.width
            let fracy = jj.y / g.size.height

            Task {
              await MainActor.run {
                theDelegate.pointerLocation = jj // CGPoint(x: fracx, y: fracy)
              }
            }
            return arg
          }
        }
      }
      //      SceneControlsView(scene: delegate.scene, paused: $paused ).frame(minWidth: 600)
      PreferencesView(shdr: shader)
    }
  }


  func getScene() -> SCNScene {
    //    self.config = ConfigControllerT3SCN(shader)

    let scene = SCNScene()
    let rootNode = scene.rootNode

    let c = SCNCamera()
    c.usesOrthographicProjection = false
    c.zNear = 0
    c.zFar = 1677 // this seems to be the maximum value:  1678 doesn't work

    let myCameraNode = SCNNode()
    myCameraNode.camera = c
    myCameraNode.name = "Camera node"

    let planeSize = CGSize(width: 16, height: 9)
    let cd = tan(myCameraNode.camera!.fieldOfView * CGFloat.pi / 180.0) * (myCameraNode.camera!.projectionDirection == .vertical ? planeSize.height : planeSize.width) / 2.0
    myCameraNode.position = SCNVector3(0, 0, cd )



    rootNode.addChildNode(myCameraNode)


    let nn = getProgram()
    rootNode.addChildNode(nn)


    //    let target = SCNLookAtConstraint(target: nn)
    //    target.isGimbalLockEnabled = true
    //    myCameraNode.constraints = [target]

    scene.background.contents = XColor.orange
    scene.isPaused = false
    
    return scene
  }




  func getProgram() -> SCNNode {
    let j = SCNMaterial( )

    let planeSize = CGSize(width: 16, height: 9)



    //    let cd = tan(myCameraNode.camera!.fieldOfView * CGFloat.pi / 180.0) * (myCameraNode.camera!.projectionDirection == .vertical ? planeSize.height : planeSize.width) / 2.0
    //    myCameraNode.position = SCNVector3(0, 0, cd )

    let p = SCNProgram()

    p.fragmentFunctionName = String(shader.myName + "______Fragment")
    p.vertexFunctionName = "vertex_function"

    // FIXME: this is broken -- need to split out the SceneKit shaders
    p.library = shader.library // functionMaps["SceneShaders"]!.libs.first(where: {$0.label == self.library })!




    p.handleBinding(ofBufferNamed: "mouse",
                    frequency: .perFrame,
                    handler: {
      (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
      var z = theDelegate.hitLocation
        buffer.writeBytes(&z, count: MemoryLayout.size(ofValue: z))
      }
  )


    if let shad = shader as? ParameterizedShader {


      // get the metadata
      shad.getMetadata()


      // FIXME:
      // this could indeed be  justInitialization()
      // run the initialization shader here to get default values.


//      shad.justInitialization()

      /*
      var ibl = 8
      if let aa = (shad.metadata.fragmentArguments?.filter { $0.name == "in" })?.first {
        ibl = aa.bufferDataSize
      }
      if ibl == 0 { ibl = 8 }

      if let ib = device.makeBuffer(length: ibl, options: [.storageModeShared ]) {
        ib.label = "defaults buffer for \(shader.myName)"
        ib.contents().storeBytes(of: 0, as: Int.self)
        shader.initializationBuffer = ib
      }
*/

      // now I should also build the pref view -- and populate the initialization buffer with values from UserDefaults


      // What I have not yet figured out is how to initialize the values on first use (before UserDefault is set)



      //    Task {
      //        justInitialization()
      //    }

      // FIXME:
      // I could also use key-value coding on an nsdata object
      // on geometry or material call  setValue: forKey: "uni"

      // Bind the name of the fragment function parameters to the program.
      /*      p.handleBinding(ofBufferNamed: "uni",
       frequency: .perFrame,
       handler: {
       (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
       //                           let s = renderer.currentViewport.size
       let s = planeSize
       ttt.currentTime = now()

       var u = self.setupUniform(size: CGSize(width: s.width * 10.0, height: s.height * 10), times: ttt)
       buffer.writeBytes(&u, count: MemoryLayout<Uniform>.stride)

       })
       */


      // At this point, if the metadata indicates that I need an input buffer ...


      p.handleBinding(ofBufferNamed: "in",
                      frequency: .perFrame,
                      handler: {
        (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
        if let ib = shad.initializationBuffer {
//          var jj = Int32(40)
//          buffer.writeBytes(&jj, count: MemoryLayout<Int32>.stride)
               buffer.writeBytes(ib.contents(), count: ib.length)
        } else {
          var zero = 0
          buffer.writeBytes(&zero, count: MemoryLayout<Double>.stride)
        }
      })
    }

    if let shad = shader as? ShaderFilter {




      // FIXME: check out "setArguments" in the Shader -- that is where the arguments get set.

//      for i in 0..<shad.fragmentTextures.count {
//        setFragmentTexture(i)
//        renderEncoder.setFragmentTexture( fragmentTextures[i].texture, index: fragmentTextures[i].index)
//      }

      for k in shad.fragmentTextures {
//        let materialProperty = SCNMaterialProperty(contents: k.image)
        let materialProperty = SCNMaterialProperty(contents: k.getTexture() )
        j.setValue(materialProperty, forKey: k.name)
      }

    }




    j.program = p
    j.isDoubleSided = true

    /*
     let im = XImage.init(named: "london")!
     let matprop = SCNMaterialProperty.init(contents: im)
     j.setValue(matprop, forKey: "tex")
     j.setValue(initializationBuffer, forKey: "in")
     */

    // Why does the size not matter here???
    let g = SCNPlane(width: planeSize.width, height: planeSize.height)

    g.materials = [j]


    let gn = SCNNode(geometry: g)
    gn.name = "Shader plane node"

    return gn

    // I could set the background to a CAMetalLayer and then render into it.....

    //    let target = SCNLookAtConstraint(target: gn)
    //    target.isGimbalLockEnabled = true
    //    myCameraNode.constraints = [target]


    //    self.dist = cd

    // FIXME: find a home for these
    /*
     self.rootNode.addChildNode(gn)
     self.background.contents = XColor.orange
     self.isPaused = false
     */
  }



  /*
  func doMouseDetection() {
    // FIXME: what is this in iOS land?  What is it in mac land?

#if os(macOS)
    Task {

      await MainActor.run {
        var scale : Int = 1
        let eml = NSEvent.mouseLocation

        if let xvv = xview,
           let xww = xvv.window {
          let wp = xww.convertPoint(fromScreen: eml)
          let ml = xvv.convert(wp, from: nil)

          if xvv.isMousePoint(ml, in: xvv.bounds) {
            Task { await setup.setTouch(ml) }
          }
          scale = Int(xvv.window?.screen?.backingScaleFactor ?? 1)
        }
      }
    }
#endif

#if targetEnvironment(macCatalyst)
    if let xvv = xview {
      let ourEvent = CGEvent(source: nil)!
      let point = ourEvent.unflippedLocation
      let xscale =  xvv.window!.screen.scale // was scale
                                             //      let ptx = CGPoint(x: point.x / xscale, y: point.y / xscale)
                                             //


      let offs = (NSClassFromString("NSApplication")?.value(forKeyPath: "sharedApplication.windows._frame") as? [CGRect])![0]

      //      let offs = ws.value(forKeyPath: "_frame") as! CGRect
      //      let soff = ws.value(forKeyPath: "screen._frame") as! CGRect

      let loff = xvv.convert(CGPoint.zero, to: xvv.window!)
      let ptx = CGPoint(x: point.x - offs.minX, y: point.y - offs.minY )
      let lpoint = CGPoint(x: ptx.x - loff.x, y: ptx.y - loff.y)

      scale = Int(xscale)

      // I don't know why the 40 is needed -- but it seems to work
      let zlpoint = CGPoint(x: lpoint.x, y: lpoint.y - xvv.bounds.height - 40 )
      if zlpoint.x >= 0 && zlpoint.y >= 0 && zlpoint.x < xvv.bounds.width && zlpoint.y < xvv.bounds.height {
        Task { await setup.setTouch(zlpoint) }
      }
    }
#endif
  }
*/



}


class MyDelegate : NSObject, SCNSceneRendererDelegate {
  var showsStatistics : Bool = true
  var debugOptions: SCNDebugOptions = []
  var pointerLocation : CGPoint = CGPoint(x: 0, y: 0)
  var hitLocation : SIMD2<Float> = .zero

  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    renderer.showsStatistics = self.showsStatistics
    renderer.debugOptions = self.debugOptions
  }

  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    Task {

      await MainActor.run {
    let pov = renderer.pointOfView!.position
    let jj = pointerLocation
    let bxx = renderer.currentViewport  //  childNodes[1].boundingBox
    let bbb = scene.rootNode.boundingBox

    let xxx = bbb.min.x + (jj.x / bxx.width) * (bbb.max.x - bbb.min.x)
    let yyy = bbb.min.y + (jj.y / bxx.height) * (bbb.max.y - bbb.min.y)



/*
//            Task {

//              await MainActor.run {
        var scale : Int = 1
        let eml = NSEvent.mouseLocation
        if let xvv = xview,
           let xww = xvv.window {
          let wp = xww.convertPoint(fromScreen: eml)
          let ml = xvv.convert(wp, from: nil)

          if xvv.isMousePoint(ml, in: xvv.bounds) {
            Task { await setup.setTouch(ml) }
          }
          scale = Int(xvv.window?.screen?.backingScaleFactor ?? 1)
        }
//              }
//            }
*/





    // FIXME:
//    let zzy = scene.rootNode.hitTestWithSegment(from: kk.rootNode.childNodes.first!.position, to: SCNVector3(x: xxx, y: yyy, z: -0.001))
    let zzy = renderer.hitTest(jj)
//            let zzz = kk.physicsWorld.rayTestWithSegment(from: kk.rootNode.childNodes.first!.position, to: SCNVector3(x: xxx, y: yyy, z: -0.001))  //  hitTest(point: k, bounds: g.frame(in: .global))

        for n in zzy {
          if n.node.name == "Shader plane node" {
            Task {
              await MainActor.run {
                let bbb = n.node.boundingBox
                let lc = n.localCoordinates
                let xx = (lc.x - bbb.min.x) / (bbb.max.x - bbb.min.x)
                let yy = (lc.y - bbb.min.y) / (bbb.max.y - bbb.min.y)
                self.hitLocation = .init(Float(xx),Float(yy) )
                print(self.hitLocation)
              }
            }
          }
        }
//            print("ok")

//                //              print(k, g.safeAreaInsets, offs, g, z, zz)
//                //              print(jj, j)
//                 await self.shader.setup.setTouch(jj) // mouseLocation

        //                }


        //                let offs = NSClassFromString("NSApplication")?.value(forKeyPath: "sharedApplication.windows._frame") as? [CGRect])![0]

        //              let loff = xvv.convert(CGPoint.zero, to: xvv.window!)
        //                let ptx = CGPoint(x: point.x - offs.minX, y: point.y - offs.minY )
        //              let lpoint = CGPoint(x: ptx.x - loff.x, y: ptx.y - loff.y)

        //                scale = xscale

        // I don't know why the 40 is needed -- but it seems to work
        //                let zlpoint = CGPoint(x: lpoint.x, y: lpoint.y - xvv.bounds.height - 40 )
        //                if zlpoint.x >= 0 && zlpoint.y >= 0 && zlpoint.x < xvv.bounds.width && zlpoint.y < xvv.bounds.height {
        //                  delegate.setup.mouseLoc = zlpoint
        //                }


        //              }}
//              } else {
//                //            print("hunh?")
//              }
//            }
      }
    }

  }

}
