
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

struct FoldersListView : View {
  var folders : [ShaderLib]

  var body: some View {
    List {
      ForEach( folders ) { li in
        NavigationLink(destination: ShaderListView(items: li.items)) {
        HStack {
          Text(li.id).frame(maxWidth: .infinity, alignment: .leading)

         }
       }.frame(minWidth: 100, maxWidth: 400)
     }
  }
  }
}

struct ShaderView : View {
  var delegate : MetalDelegate

  var body : some View {
    MetalViewC(delegate: delegate)
      .onAppear {
        delegate.play()
      }
      .onDisappear {
        delegate.stop()
      }
  }
}

struct ShaderListView : View {
  var items : [ShaderLeaf]

  var body: some View {
        List {
          ForEach( items, id: \.self ) { li  in
            NavigationLink(destination:
                            ShaderView(delegate: MetalDelegate(shader: li.rm))
            ) {
              HStack {
                Text( li.id ).frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }.frame(minWidth: 100, maxWidth: 400)
        }
      }
}

struct ShaderLibraryView : View {
  var fl : [ShaderLib]

  init() {
    fl = ShaderLib.folderList
/*    if let sl = UserDefaults.standard.string(forKey: "selectedLibrary"), self.state.libName != sl {
      self.state.lib = fl.first(where: { $0.id == sl })
      if let ss = UserDefaults.standard.string(forKey: "selectedShader"), self.state.delegate.shader?.id != ss {
        self.state.delegate.shader = self.state.lib?.items.first(where: { $0.id == ss} )?.rm
      }
    }
 */
  }

  var body: some View {
    NavigationView {
      FoldersListView(folders : fl)
        .toolbar {
          Button(action: toggleSidebar) {
            Image(systemName: "sidebar.left")
              .help("Toggle Sidebar")
          }
        }
      Text("No Sidebar Selection")
      Text("No Shader Selection")
    }
  }

  private func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
  }
    /*


    let j = MetalViewC(delegate: state.delegate)  // shader: ss.rm)
    let c = ControlsView( frameTimer: state.delegate.frameTimer, delegate: state.delegate, metalView: j.mtkView).frame(minWidth: 600)
    let m : AnyView = AnyView(VStack { j; c} )
    return HStack {
      Text(uuid.uuidString).hidden().frame(width: 0)
      VStack {
        HSplitView( ) {
          ShaderListView(state: state)
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
     */
}
