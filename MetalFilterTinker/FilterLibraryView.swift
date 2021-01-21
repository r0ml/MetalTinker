
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import os
import SwiftUI
import Combine
import SceneKit
import SpriteKit
import Metal

// import CoreVideo

class FilterShaderLeaf : Identifiable, Equatable, Hashable {
  static func == (lhs: FilterShaderLeaf, rhs: FilterShaderLeaf) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
  }

  var rm : SKScene

  public var id : String {
    return String(describing: type(of: rm))
  }

  init(_ r : SKScene) {
    rm = r
  }
}

class FilterShaderLib : Identifiable, Equatable, Hashable {
  static func == (lhs: FilterShaderLib, rhs: FilterShaderLib) -> Bool {
    return lhs.id == rhs.id
  }

  var id : String

  func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
  }

  var lib : Dictionary<String, SKScene>

  init(lib l: String) {
    id = l
    lib = filtery[l]!
  }

  fileprivate static let folderList : [FilterShaderLib] = {
    return filtery.keys.sorted().map { FilterShaderLib(lib: $0) }
//    return metalLibraries.filter({ $0.label != "default"  }).sorted { $0.label!.lowercased() < $1.label!.lowercased() }.map { SpriteShaderLib(lib: $0)}
  }()

  lazy var items : [FilterShaderLeaf] = {
    let res = Array(lib.keys)
    return (Set(res).sorted { $0.lowercased() < $1.lowercased() }).map {(z : String) in FilterShaderLeaf(lib[z]!) }
  }()
}

class FilterLibState : ObservableObject {
  @Published var lib : FilterShaderLib? {
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

  var items : [FilterShaderLeaf] = []

  var libName : String {
    return lib?.id ?? "none"
  }

//  var shaderName : String {
//    return shader?.id ?? "none"
//  }

  var delegate = FilterKitDelegate()

}


struct FilterLeftPane : View {
  @ObservedObject var state : FilterLibState
  var fl : [FilterShaderLib]

  init(state : FilterLibState) {
    self.state = state
    fl = FilterShaderLib.folderList
  }

  func moveSelection(_ n : Int, _ sv : ScrollViewProxy) {
    let a = FilterShaderLib.folderList
    if let cc = state.lib, let b = a.firstIndex(of: cc) {
      let d = min(a.count - 1, max(0, b + n))
      sv.scrollTo(a[d], anchor: .center)
      setLib(a[d])
    }

  }

  func setLib(_ li : FilterShaderLib) {
    state.lib = li
//    state.delegate.stop()
//    state.delegate.shader = nil
    UserDefaults.standard.set(li.id, forKey: "selectedFilterGroup")
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
//            self.state.delegate.shader = state.lib?.items.first?.rm
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

struct FilterRightPane : View {
  @ObservedObject var state : FilterLibState


/*  func moveSelection(_ n : Int, _ sv : ScrollViewProxy) {
    let a = state.items
    if let cc = state.delegate.shader, let b = a.firstIndex(where: { $0.rm == cc } ) {
      let d = min(a.count - 1, max(0, b + n))
      sv.scrollTo(a[d], anchor: .center)
      setShader(a[d])
    }

  }
 */


  func setShader(_ li : FilterShaderLeaf) {
    self.state.delegate.shader = li
//    self.state.delegate.play()
    self.state.objectWillChange.send()
    UserDefaults.standard.set(li.id, forKey: "selectedFilter")
  }

  var body: some View {

    return ScrollView {
      ScrollViewReader { sv -> AnyView in

        let bk = KeyEventHandling("right")  { event in
          if let c = event.characters?.unicodeScalars.first?.value {
          switch(c) {
          case 0xf700:
          //  moveSelection(-1, sv)
          break
          case 0xf701:
          //  moveSelection(1, sv)
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

class FilterKitDelegate : NSObject, ObservableObject {
  @Published var shader : FilterShaderLeaf?
//  @Published var scene : SKScene = SKScene()
}

struct FilterWrapperView : View {
  @ObservedObject var delegate : FilterKitDelegate

  var body: some View {
    VStack {
//      SpriteView.init(scene: <#T##SKScene#>, transition: <#T##SKTransition?#>, isPaused: <#T##Bool#>, preferredFramesPerSecond: <#T##Int#>, options: <#T##SpriteView.Options#>, shouldRender: <#T##(TimeInterval) -> Bool#>)
      FilterView(scene: delegate.scene, options: [.allowsTransparency])
    }
  }
}

struct FilterLibraryView : View {
  @ObservedObject var state : FilterLibState
  @State var uuid = UUID()
  var fl : [FilterShaderLib]

  init() {
    state = FilterLibState()
    fl = FilterShaderLib.folderList
    if let sl = UserDefaults.standard.string(forKey: "selectedFilterGroup"), self.state.libName != sl {
      self.state.lib = FilterShaderLib(lib: sl)
      if let ss = UserDefaults.standard.string(forKey: "selectedFilter"), self.state.delegate.shader?.id != ss {
        if let p = self.state.lib?.lib[ss] {
          self.state.delegate.shader = FilterShaderLeaf(p)
      }
    }
  }
  }

  var thumbs : [NSImage] = [NSImage.init(named: "BrokenImage")!]

  var body: some View {

    let j = FilterWrapperView(delegate: state.delegate)  // shader: ss.rm)
//    let c = ControlsView( frameTimer: state.delegate.frameTimer, delegate: state.delegate, metalView: j.mtkView).frame(minWidth: 600)
    let m : AnyView = AnyView(VStack { j /* ; c */} )
    return HStack {
      Text(uuid.uuidString).hidden().frame(width: 0)
      VStack {
        HSplitView( ) {
          FilterLeftPane(state: state)
          FilterRightPane(state: state)
        }


  //      PreferencesView(shader: state.delegate.shader)
      }.onReceive(Just(state.delegate.shader)) {s in
//        print("changed shader to \(s?.myName)")
        if let k = state.delegate.shader?.rm {
          state.delegate.scene = k
          state.delegate.objectWillChange.send()

        }

      //  print("changed shader")
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



var filtery : Dictionary<String, Dictionary<String, SKScene>> = {
  var a = Dictionary<String, Dictionary<String, SKScene>>()

//  a["SimpleFilter"] = register( [Simple3() ] )

//  a["3d scene"] = register( [] )
//  a["Shapes3d"] = register( [] )
//  a["Spheres"] = register( [] )

  return a
}()

// ==========================================================================

func register(_ dd : [SKScene]) -> Dictionary<String, SKScene> { // _ d : inout Dictionary<String, SceneProtocol>) {
  var b = Dictionary<String, SKScene>()
  dd.forEach { d in
    let a = String(describing: type(of: d))
    b[a] = d
  }
  return b
}
