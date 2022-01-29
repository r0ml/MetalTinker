
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import os
import SwiftUI
import Combine
import SceneKit
import SpriteKit
import Metal

struct SceneShaderLeaf : Identifiable, Equatable, Hashable {
  static func == (lhs: SceneShaderLeaf, rhs: SceneShaderLeaf) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
  }

  var rm : T1SCNScene

  public var id : String {
    if let k = rm as? T3ShaderSCNScene {
      return k.shader
    } else {
      return String(describing: type(of: rm))
    }
  }

  init(_ r : T1SCNScene) {
    rm = r
  }
}

class SceneShaderLib : Identifiable, Equatable, Hashable {
  static func == (lhs: SceneShaderLib, rhs: SceneShaderLib) -> Bool {
    return lhs.id == rhs.id
  }

  var id : String

  func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
  }

  var lib : Dictionary<String, T1SCNScene>

  init(lib l: String) {
    id = l
    lib = scenery[l]!
  }

  fileprivate static let folderList : [SceneShaderLib] = {
    return scenery.keys.sorted().map { SceneShaderLib(lib: $0) }
  }()

  lazy var items : [SceneShaderLeaf] = {
    let res = Array(lib.keys)
    return (Set(res).sorted { $0.lowercased() < $1.lowercased() }).map {(z : String) in SceneShaderLeaf(lib[z]!) }
  }()
}

struct SceneListView : View {
  var items : [SceneShaderLeaf]

  var body: some View {
    List {
      ForEach( items, id: \.self ) { li  in
        NavigationLink(destination: SceneWrapperView(delegate: SKDelegate(shader: li))) {
          HStack {
            Text( li.id ).frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }.frame(minWidth: 100, maxWidth: 400)
    }
  }
}

class SKDelegate : NSObject, ObservableObject {
  var scene : T1SCNScene
  var shader : SceneShaderLeaf
  init(shader : SceneShaderLeaf) {
    self.shader = shader
    self.scene = shader.rm
  }
}

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

struct SceneWrapperView : View {
  @ObservedObject var delegate : SKDelegate
  @GestureState var magnifyBy : CGFloat = 1
  @GestureState var dragger : CGPoint = .zero

  @State var paused = false

  var mag : some Gesture {
    MagnificationGesture()
      .updating($magnifyBy)  {
        cs, gs, t in gs = cs
      }
      .onChanged { m in
        if let x = delegate.scene as? T3SCNScene {
          DispatchQueue.main.async { x.zoom(m) }
        }
      }
      .onEnded { g in
        if let x = delegate.scene as? T3SCNScene {
          DispatchQueue.main.async { x.updateZoom(g) }
        }
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
          if let sc = delegate.scene as? T3ShaderSCNScene {
            let zz = sc.hiTest(point: cs.location, bounds: g.frame(in: .global))

            //    print("hitTest: \(zz)")
            sc.touchLoc = zz
            // FIXME: need this to be non-null, but it should be the result of hittesting the start location, not the current location
            sc.startDragLoc = zz
          }
        }
        let z = delegate.scene
        let _ = z.setSize(g.size)
        SceneView(scene: z,
                  options: paused ? [] : [ .allowsCameraControl, .rendersContinuously ],
                  //                      preferredFramesPerSecond: 120,
                  antialiasingMode: SCNAntialiasingMode.multisampling4X,
                  delegate: z
        )
          .gesture(mag)
          .gesture(drag)
      }
      SceneControlsView(scene: delegate.scene, paused: $paused ).frame(minWidth: 600)
    }
  }
}

struct SidebarView : View {
  var folderList : [SceneShaderLib]

  var body: some View {
    List {
      ForEach(folderList) {f in
        NavigationLink(destination: SceneListView(items: f.items) ) {
          Text(f.id)
        }
      }
    }.listStyle(SidebarListStyle())
  }
}

struct SceneLibraryView : View {
  var fl : [SceneShaderLib]

  init() {
    fl = SceneShaderLib.folderList
    /*
     if let sl = UserDefaults.standard.string(forKey: "selectedGroup"), self.state.libName != sl {
     self.state.lib = NewShaderLib(lib: sl)
     if let ss = UserDefaults.standard.string(forKey: "selectedScene"), self.state.delegate.shader?.id != ss {
     if let p = self.state.lib?.lib[ss] {
     self.state.delegate.shader = NewShaderLeaf(p)
     }
     }
     }
     */
  }

  var body: some View {
    NavigationView {
      SidebarView(folderList: fl)

      #if os(macOS)
        .toolbar {
          Button(action: toggleSidebar) {
            Image(systemName: "sidebar.left")
              .help("Toggle Sidebar")
          }
        }
      #endif

      Text("No Sidebar Selection")
      Text("No Scene Selection")
    }
  }

  #if os(macOS)
  private func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
  }
  #endif

  /*

   let j = SceneWrapperView(delegate: state.delegate)  // shader: ss.rm)
   // let c = ControlsView( frameTimer: state.delegate.frameTimer, delegate: state.delegate, metalView: j.mtkView).frame(minWidth: 600)
   let m : AnyView = AnyView(VStack { j /* ; c */} )
   let p  = PreferencesView(scene: state.delegate.shader?.rm as? T3ShaderSCNScene)

   return HStack {
   Text(uuid.uuidString).hidden().frame(width: 0)
   VStack {
   HSplitView( ) {
   NewLeftPane(state: state)
   NewRightPane(state: state)
   }
   p


   }.onReceive(Just(state.delegate.shader)) {s in
   //        print("changed shader to \(s?.myName)")
   if let k = state.delegate.shader?.rm {
   state.delegate.scene = k

   state.delegate.objectWillChange.send()

   }
   }
   VStack {
   m
   }
   }
   }


   */

}
