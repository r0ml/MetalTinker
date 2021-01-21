
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import os
import SwiftUI
import Combine
import SceneKit
import SpriteKit
import Metal

// import CoreVideo

class NewShaderLeaf : Identifiable, Equatable, Hashable {
  static func == (lhs: NewShaderLeaf, rhs: NewShaderLeaf) -> Bool {
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

class NewShaderLib : Identifiable, Equatable, Hashable {
  static func == (lhs: NewShaderLib, rhs: NewShaderLib) -> Bool {
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

  fileprivate static let folderList : [NewShaderLib] = {
    return scenery.keys.sorted().map { NewShaderLib(lib: $0) }
    //    return metalLibraries.filter({ $0.label != "default"  }).sorted { $0.label!.lowercased() < $1.label!.lowercased() }.map { NewShaderLib(lib: $0)}
  }()

  lazy var items : [NewShaderLeaf] = {
    let res = Array(lib.keys)
    return (Set(res).sorted { $0.lowercased() < $1.lowercased() }).map {(z : String) in NewShaderLeaf(lib[z]!) }
  }()
}

class NewLibState : ObservableObject {
  @Published var lib : NewShaderLib? {
    willSet {
      items = newValue?.items ?? []
    }
  }
  //  @Published var shader : ShaderLeaf?
  //    willSet {
  //      if let m = newValue {
  //        self.mtv = MetalViewC(shader: m.rm)
  //      }
  //    }

  var items : [NewShaderLeaf] = []

  var libName : String {
    return lib?.id ?? "none"
  }

  //  var shaderName : String {
  //    return shader?.id ?? "none"
  //  }

  var delegate = SKDelegate()

}


struct NewLeftPane : View {
  @ObservedObject var state : NewLibState
  var fl : [NewShaderLib]

  init(state : NewLibState) {
    self.state = state
    fl = NewShaderLib.folderList
  }

  func moveSelection(_ n : Int, _ sv : ScrollViewProxy) {
    let a = NewShaderLib.folderList
    if let cc = state.lib, let b = a.firstIndex(of: cc) {
      let d = min(a.count - 1, max(0, b + n))
      sv.scrollTo(a[d], anchor: .center)
      setLib(a[d])
    }

  }

  func setLib(_ li : NewShaderLib) {
    state.lib = li
    //    state.delegate.stop()
    state.delegate.shader = nil
    UserDefaults.standard.set(li.id, forKey: "selectedGroup")
    state.objectWillChange.send()
  }

  var body: some View {
    ScrollView {
      ScrollViewReader { sv -> AnyView in

        let bk = KeyEventHandling("left") { event in
          print(">> left pane key \(event.charactersIgnoringModifiers ?? "")")
          if let c = event.characters?.unicodeScalars.first?.value {
            switch(c) {
            case 0xf700:
              moveSelection(-1, sv)
            case 0xf701:
              moveSelection(1, sv)
            case 0xf702:
              print("key left")
            case 0xf703:
              NotificationCenter.default.post(name: Notification.Name("focus"), object: "right")
              self.state.delegate.shader = state.lib?.items.first
              //            self.state.delegate.play()
              self.state.objectWillChange.send()
            //        print("key right")
            default:
              print(">> left pane unknown key \(event.keyCode)")
            }
          }
        }

        return AnyView(
          ForEach( fl ) { li in
            //            GeometryReader {g in
            HStack {
              Text(li.id).frame(maxWidth: .infinity, alignment: .leading)

              //            }
            }
            //     .padding(EdgeInsets.init(top: 4, leading: 0, bottom: 4, trailing: 0))
            .background(
              li == state.lib ? Color(NSColor.lightGray) : Color(NSColor.windowBackgroundColor) )
            .onTapGesture {
              // I need to force scrolling back to the top
              // or I get weird artifacts in the new selection values.
              // by 'unselecting' first, it resets

              setLib(li)
              bk.focus()
            }
          }.frame(minWidth: 100, maxWidth: 400)
          .background( bk )
        )
      }
    }
  }
}

struct NewRightPane : View {
  @ObservedObject var state : NewLibState

  func moveSelection(_ n : Int, _ sv : ScrollViewProxy) {
    let a = state.items
    if let cc = state.delegate.shader, let b = a.firstIndex(where: { $0 == cc } ) {
      let d = min(a.count - 1, max(0, b + n))
      sv.scrollTo(a[d], anchor: .center)
      setShader(a[d])
    }
  }

  func setShader(_ li : NewShaderLeaf) {
    self.state.delegate.shader = li
    //    self.state.delegate.play()
    self.state.objectWillChange.send()
    UserDefaults.standard.set(li.id, forKey: "selectedScene")
  }

  var body: some View {

    return ScrollView {
      ScrollViewReader { sv -> AnyView in

        let bk = KeyEventHandling("right")  { event in
          if let c = event.characters?.unicodeScalars.first?.value {
            switch(c) {
            case 0xf700:
              moveSelection(-1, sv)
              break
            case 0xf701:
              moveSelection(1, sv)
              break
            case 0xf702:
              //            self.state.delegate.stop()
              self.state.delegate.shader = nil
              self.state.objectWillChange.send()
              NotificationCenter.default.post(name: Notification.Name("focus"), object: "left")
            case 0xf703:
              print("key right")
            default:
              print(">> right pane unknown key \(event.keyCode)")
            }
          }
        }



        return
          AnyView(
            ForEach( state.items, id: \.self ) { li  in
              HStack {

                Text( li.id ).frame(maxWidth: .infinity, alignment: .leading)
              }
              .background(li.id == state.delegate.shader?.id ? Color(NSColor.lightGray) : Color(NSColor.windowBackgroundColor))
              .onTapGesture {
                setShader(li)
                bk.focus()
              }
            }.background( bk )
          )
      }.frame(minWidth: 100, maxWidth: 400)
    }
  }
}

class SKDelegate : NSObject, ObservableObject {
  @Published var scene : T1SCNScene = T1SCNScene()
  @Published var shader : NewShaderLeaf?
  //  @Published var skscene : SKScene = SKScene()
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

//  @StateObject var coordinator = SceneCoordinator()

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
//    let j =

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
      
      //      SpriteView.init(scene: <#T##SKScene#>, transition: <#T##SKTransition?#>, isPaused: <#T##Bool#>, preferredFramesPerSecond: <#T##Int#>, options: <#T##SpriteView.Options#>, shouldRender: <#T##(TimeInterval) -> Bool#>)
      //      SpriteView(scene: delegate.skscene, options: [.allowsTransparency])
    }

    /// Convert the points on the screen to the 3D scene

  }
}


struct SceneLibraryView : View {
  @ObservedObject var state : NewLibState
  @State var uuid = UUID()
  var fl : [NewShaderLib]

  init() {
    state = NewLibState()
    fl = NewShaderLib.folderList
    if let sl = UserDefaults.standard.string(forKey: "selectedGroup"), self.state.libName != sl {
      self.state.lib = NewShaderLib(lib: sl)
      if let ss = UserDefaults.standard.string(forKey: "selectedScene"), self.state.delegate.shader?.id != ss {
        if let p = self.state.lib?.lib[ss] {
          self.state.delegate.shader = NewShaderLeaf(p)
        }
      }
    }
  }

  var thumbs : [NSImage] = [NSImage.init(named: "BrokenImage")!]

  var body: some View {
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

        //        print("changed shader")
      }
      VStack {
        m
        //        if state.shader != nil {
        //          state.mtv!.frame(minWidth: 400, idealWidth: 800, maxWidth: 3200, minHeight: 225, idealHeight: 450, maxHeight: 1800, alignment: .top)
        //            .aspectRatio(16/9.0, contentMode: .fit).layoutPriority(101.0)
        //            .onDisappear(perform: {
        //              state.shader?.rm.stop()
        //            })


      }
    } // .onReceive(self.state.$shader) {z in
    //       self.uuid = UUID()
    //     }
  }
}
