
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import os
import SwiftUI
import SceneKit
import SpriteKit
import Metal

// import CoreVideo

// FIXME: bring me in for iOS

#if os(macOS)
class SpriteShaderLeaf : Identifiable, Equatable, Hashable {
  static func == (lhs: SpriteShaderLeaf, rhs: SpriteShaderLeaf) -> Bool {
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

class SpriteShaderLib : Identifiable, Equatable, Hashable {
  static func == (lhs: SpriteShaderLib, rhs: SpriteShaderLib) -> Bool {
    return lhs.id == rhs.id
  }

  var id : String

  func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
  }

  var lib : Dictionary<String, SKScene>

  init(lib l: String) {
    id = l
    lib = spritery[l]!
  }

  fileprivate static let folderList : [SpriteShaderLib] = {
    return spritery.keys.sorted().map { SpriteShaderLib(lib: $0) }
//    return metalLibraries.filter({ $0.label != "default"  }).sorted { $0.label!.lowercased() < $1.label!.lowercased() }.map { SpriteShaderLib(lib: $0)}
  }()

  lazy var items : [SpriteShaderLeaf] = {
    let res = Array(lib.keys)
    return (Set(res).sorted { $0.lowercased() < $1.lowercased() }).map {(z : String) in SpriteShaderLeaf(lib[z]!) }
  }()
}

class SpriteLibState : ObservableObject {
  @Published var lib : SpriteShaderLib? {
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

  var items : [SpriteShaderLeaf] = []

  var libName : String {
    return lib?.id ?? "none"
  }

//  var shaderName : String {
//    return shader?.id ?? "none"
//  }

  var delegate = SpriteKitDelegate()

}


struct SpriteLeftPane : View {
  @ObservedObject var state : SpriteLibState
  var fl : [SpriteShaderLib]

  init(state : SpriteLibState) {
    self.state = state
    fl = SpriteShaderLib.folderList
  }

  func moveSelection(_ n : Int, _ sv : ScrollViewProxy) {
    let a = SpriteShaderLib.folderList
    if let cc = state.lib, let b = a.firstIndex(of: cc) {
      let d = min(a.count - 1, max(0, b + n))
      sv.scrollTo(a[d], anchor: .center)
      setLib(a[d])
    }

  }

  func setLib(_ li : SpriteShaderLib) {
    state.lib = li
//    state.delegate.stop()
//    state.delegate.shader = nil
    UserDefaults.standard.set(li.id, forKey: "selectedSpriteGroup")
    state.objectWillChange.send()
  }

  var body: some View {
    ScrollView {
      ScrollViewReader { sv -> AnyView in
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
      }
    }
  }
}

struct SpriteRightPane : View {
  @ObservedObject var state : SpriteLibState


/*  func moveSelection(_ n : Int, _ sv : ScrollViewProxy) {
    let a = state.items
    if let cc = state.delegate.shader, let b = a.firstIndex(where: { $0.rm == cc } ) {
      let d = min(a.count - 1, max(0, b + n))
      sv.scrollTo(a[d], anchor: .center)
      setShader(a[d])
    }

  }
 */


  func setShader(_ li : SpriteShaderLeaf) {
    self.state.delegate.shader = li
//    self.state.delegate.play()
    self.state.objectWillChange.send()
    UserDefaults.standard.set(li.id, forKey: "selectedSprite")
  }

  var body: some View {

    return ScrollView {
      ScrollViewReader { sv in

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
    }.frame(minWidth: 100, maxWidth: 400)
    }
  }
}

class SpriteKitDelegate : NSObject, ObservableObject {
  @Published var shader : SpriteShaderLeaf?
  @Published var scene : SKScene = SKScene()
}

struct SpriteWrapperView : View {
  @ObservedObject var delegate : SpriteKitDelegate

  var body: some View {
    VStack {
//      SpriteView.init(scene: <#T##SKScene#>, transition: <#T##SKTransition?#>, isPaused: <#T##Bool#>, preferredFramesPerSecond: <#T##Int#>, options: <#T##SpriteView.Options#>, shouldRender: <#T##(TimeInterval) -> Bool#>)
      SpriteView(scene: delegate.scene, options: [.allowsTransparency])
    }
  }
}

struct SpriteLibraryView : View {
  @ObservedObject var state : SpriteLibState
  @State var uuid = UUID()
  var fl : [SpriteShaderLib]

  init() {
    state = SpriteLibState()
    fl = SpriteShaderLib.folderList
    if let sl = UserDefaults.standard.string(forKey: "selectedSpriteGroup"), self.state.libName != sl {
      self.state.lib = SpriteShaderLib(lib: sl)
      if let ss = UserDefaults.standard.string(forKey: "selectedSprite"), self.state.delegate.shader?.id != ss {
        if let p = self.state.lib?.lib[ss] {
          self.state.delegate.shader = SpriteShaderLeaf(p)
      }
    }
  }
  }

  var thumbs : [XImage] = [XImage.init(named: "BrokenImage")!]

  var body: some View {
  
    let j = SpriteWrapperView(delegate: state.delegate)  // shader: ss.rm)
//    let c = ControlsView( frameTimer: state.delegate.frameTimer, delegate: state.delegate, metalView: j.mtkView).frame(minWidth: 600)
    let m : AnyView = AnyView(VStack { j /* ; c */} )
    return HStack {
      Text(uuid.uuidString).hidden().frame(width: 0)
      VStack {
        HSplitView( ) {
          SpriteLeftPane(state: state)
          SpriteRightPane(state: state)
        }


  //      PreferencesView(shader: state.delegate.shader)
      }.onChange(of: state.delegate.shader) {s in
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

#endif
