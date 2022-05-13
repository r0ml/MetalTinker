// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import SceneKit

struct ShaderNodeView : View {
  @GestureState var magnifyBy : CGFloat = 1
  @GestureState var dragger : CGPoint = .zero

  @State var overImg = false
  @State var paused = false
  var shader : GenericShader
  var mouseLocation : NSPoint { NSEvent.mouseLocation }

  init(shader: GenericShader) {
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

        SceneView(scene: kk,
                  options: paused ? [] : [ .allowsCameraControl, .rendersContinuously ],
                  //                      preferredFramesPerSecond: 120,
                  antialiasingMode: SCNAntialiasingMode.multisampling4X,
                  delegate: MyDelegate()
        )
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
            let bb : CGFloat = CGFloat(multisampleCount)
            let k = g.frame(in: .global)

            let q = offs.height - k.maxY



            Task {

              if (k.minX != 0) {
                let j = CGPoint(x: (zz.x - k.minX) / bb  , y: (zz.y - k.minY ) / bb  )

                let jj = CGPoint(x: (z.x - offs.minX - k.minX) / bb, y: (z.y - offs.minY - q /* k.minY */ ) / bb )

                //              print(k, g.safeAreaInsets, offs, g, z, zz)
                //              print(jj, j)
                await self.shader.setup.setTouch(jj) // mouseLocation

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
              } else {
                //            print("hunh?")
              }
            }
            return arg
          }
        }
      }
      //      SceneControlsView(scene: delegate.scene, paused: $paused ).frame(minWidth: 600)
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






}


class MyDelegate : NSObject, SCNSceneRendererDelegate {
  var showsStatistics : Bool = true
  var debugOptions: SCNDebugOptions = []

  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    renderer.showsStatistics = self.showsStatistics
    renderer.debugOptions = self.debugOptions
  }

}
