
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SceneKit
import SwiftUI

/*
class SKDelegate : NSObject, ObservableObject {
  var scene : T1SCNScene
  var shader : SceneShaderLeaf
  init(shader : SceneShaderLeaf) {
    self.shader = shader
    self.scene = shader.rm
  }
}
*/

/*
 class SceneCoordinator : NSObject, SCNSceneRendererDelegate, ObservableObject {
 var showsStatistics : Bool = true
 var debugOptions: SCNDebugOptions = []

 func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
 renderer.showsStatistics = self.showsStatistics
 renderer.debugOptions = self.debugOptions
 }
 }
 */

struct ShaderSceneView : View {
  @GestureState var magnifyBy : CGFloat = 1
  @GestureState var dragger : CGPoint = .zero

  @State var overImg = false
  @State var paused = false
  var shader : GenericShader
  var mouseLocation : NSPoint { NSEvent.mouseLocation }
  
  init(delegate: GenericShader) {
    self.shader = delegate
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

          let kk = SCNScene()
//        let _ = { kk.background.contents =  }()
          let z = shader
          let _ = (shader.mySize = g.size)
        
        SceneView(scene: kk,
                  options: paused ? [] : [ .rendersContinuously ],
                  //                      preferredFramesPerSecond: 120,
                  antialiasingMode: SCNAntialiasingMode.multisampling4X,
                  delegate: z
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

              if (k.minX != 0) {
                let j = CGPoint(x: (zz.x - k.minX) / bb  , y: (zz.y - k.minY ) / bb  )

              let jj = CGPoint(x: (z.x - offs.minX - k.minX) / bb, y: (z.y - offs.minY - q /* k.minY */ ) / bb )

//              print(k, g.safeAreaInsets, offs, g, z, zz)
//              print(jj, j)
                self.shader.setup.mouseLoc = jj // mouseLocation

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
              return arg
            }
          }
      }
//      SceneControlsView(scene: delegate.scene, paused: $paused ).frame(minWidth: 600)
    }
  }
}
  
extension GenericShader : SCNSceneRendererDelegate {
  func renderer(_ sr : SCNSceneRenderer, willRenderScene: SCNScene, atTime: TimeInterval) {
//  Tells the delegate that the renderer has cleared the viewport and is about to render the scene.
//    fatalError("I got here")
    // run the shader and output to the texture that is used by the scene background
    
    if isRunning {
      
      if isStepping {
        isRunning = false
        isStepping = false
      }
      doRunning()
      let cq = sr.commandQueue
      ddraw( cq , nil, willRenderScene  )
    }

  }
}
