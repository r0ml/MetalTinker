
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import os
import SwiftUI
import Combine

class ShaderLeaf : Identifiable, Equatable, Hashable {
  static func == (lhs: ShaderLeaf, rhs: ShaderLeaf) -> Bool {
    return lhs.rm.myName == rhs.rm.myName
  }

  func hash(into hasher: inout Hasher) {
    rm.myName.hash(into: &hasher)
  }

  var rm : Shader

  public var id : String {
    return rm.myName
  }

  init(_ r : Shader) {
    rm = r
  }
}

class ShaderLib : Identifiable, Equatable, Hashable {
  static func == (lhs: ShaderLib, rhs: ShaderLib) -> Bool {
    return lhs.lib.label == rhs.lib.label
  }

  func hash(into hasher: inout Hasher) {
    lib.label.hash(into: &hasher)
  }

  var lib : MTLLibrary

  init(lib l: MTLLibrary) {
    lib = l
  }

  public var id : String {
    return lib.label ?? "none"
  }

  fileprivate static let folderList : [ShaderLib] = {
    return metalLibraries.filter({ $0.label != "default"  }).sorted { $0.label!.lowercased() < $1.label!.lowercased() }.map { ShaderLib(lib: $0)}
  }()

  lazy var items : [ShaderLeaf] = {
    // FIXME: need some other way to identify the list of "shaders"
    //    if cache != nil { return cache! }
    let res = lib.functionNames.compactMap { (nam) -> String? in
      var pnam : String
      if nam.hasSuffix("InitializeOptions") {
        pnam = String(nam.dropLast(17))
      } else {
        return nil
      }
      return pnam
    }
    return Set(res).sorted { $0.lowercased() < $1.lowercased() }.map { ShaderLeaf(Shader($0)) }
    //    return cache!
  }()
}

class LibState : ObservableObject {
  @Published var lib : ShaderLib? {
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

  var items : [ShaderLeaf] = []

  var libName : String {
    return lib?.id ?? "none"
  }

//  var shaderName : String {
//    return shader?.id ?? "none"
//  }

  var delegate = MetalDelegate()

}


struct LeftPane : View {
  @ObservedObject var state : LibState
  var fl : [ShaderLib]

  init(state : LibState) {
    self.state = state
    fl = ShaderLib.folderList
  }

  func moveSelection(_ n : Int, _ sv : ScrollViewProxy) {
    let a = ShaderLib.folderList
    if let cc = state.lib, let b = a.firstIndex(of: cc) {
      let d = min(a.count - 1, max(0, b + n))
      sv.scrollTo(a[d], anchor: .center)
      setLib(a[d])
    }

  }

  func setLib(_ li : ShaderLib) {
    state.lib = li
    state.delegate.stop()
    state.delegate.shader = nil
    UserDefaults.standard.set(li.id, forKey: "selectedLibrary")

   // state.objectWillChange.send()
//      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() /* + 0.03 */) {
//      self.state.lib = li
        state.objectWillChange.send()
//    }
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
            self.state.delegate.shader = state.lib?.items.first?.rm
            self.state.delegate.play()
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

struct RightPane : View {
  @ObservedObject var state : LibState


  func moveSelection(_ n : Int, _ sv : ScrollViewProxy) {
    let a = state.items
    if let cc = state.delegate.shader, let b = a.firstIndex(where: { $0.rm == cc } ) {
      let d = min(a.count - 1, max(0, b + n))
      sv.scrollTo(a[d], anchor: .center)
      setShader(a[d])
    }

  }

  func setShader(_ li : ShaderLeaf) {
    self.state.delegate.shader = li.rm
    self.state.delegate.play()
    self.state.objectWillChange.send()
    UserDefaults.standard.set(li.id, forKey: "selectedShader")
  }

  var body: some View {

    return ScrollView {
      ScrollViewReader { sv -> AnyView in

        let bk = KeyEventHandling("right")  { event in
          if let c = event.characters?.unicodeScalars.first?.value {
          switch(c) {
          case 0xf700:
            moveSelection(-1, sv)
          case 0xf701:
            moveSelection(1, sv)
          case 0xf702:
            self.state.delegate.stop()
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
        .background(li.rm == state.delegate.shader ? Color(NSColor.lightGray) : Color(NSColor.windowBackgroundColor))
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
struct LibraryView : View {
  @ObservedObject var state : LibState
  @State var uuid = UUID()
  var fl : [ShaderLib]

  init() {
    state = LibState()
    fl = ShaderLib.folderList
    if let sl = UserDefaults.standard.string(forKey: "selectedLibrary"), self.state.libName != sl {
      self.state.lib = fl.first(where: { $0.id == sl })
      if let ss = UserDefaults.standard.string(forKey: "selectedShader"), self.state.delegate.shader?.id != ss {
        self.state.delegate.shader = self.state.lib?.items.first(where: { $0.id == ss} )?.rm
      }
    }
  }

  var thumbs : [NSImage] = [NSImage.init(named: "BrokenImage")!]

  var body: some View {
    let j = MetalViewC(delegate: state.delegate)  // shader: ss.rm)
    let c = ControlsView( frameTimer: state.delegate.frameTimer, delegate: state.delegate, metalView: j.mtkView).frame(minWidth: 600)
    let m : AnyView = AnyView(VStack { j; c} )
    return HStack {
      Text(uuid.uuidString).hidden().frame(width: 0)
      VStack {
        HSplitView( ) {
          LeftPane(state: state)
          RightPane(state: state)
        }


        PreferencesView(shader: state.delegate.shader)
      }
      /*.onReceive(Just(state.delegate.shader)) {s in
        print("changed shader to \(s?.myName)")
      }*/
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
