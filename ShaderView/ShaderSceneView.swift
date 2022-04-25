
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

  @State var paused = false
  var shader : GenericShader
  
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
