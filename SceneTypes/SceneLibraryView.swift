
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import os
import SwiftUI
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
  var group : String

  public var myName : String {
    if let k = rm as? FragmentScene {
      return k.shaderName
    } else {
      return String(describing: type(of: rm))
    }
  }

  public var id : String {
    return group + "+" + myName
  }

  init(_ r : T1SCNScene, group g : String) {
    rm = r
    group = g
  }
}

class SceneShaderLib : Identifiable, Equatable, Hashable {
  static func == (lhs: SceneShaderLib, rhs: SceneShaderLib) -> Bool {
    return lhs.id == rhs.id
  }

  var libnam : String
  var group : String

  var id : String { get { return "\(group)+\(libnam)"}}

  func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
  }

  var lib : Dictionary<String, T1SCNScene>

  init(group g: String, lib l: String) {
    libnam = l
    group = g
    lib = scenery[libnam]!
  }

  static func folderList(_ group : String) -> [SceneShaderLib] {
    return scenery.keys.sorted().map { SceneShaderLib(group: group, lib: $0) }
  }

  lazy var items : [SceneShaderLeaf] = {
    let res = Array(lib.keys)
    return (Set(res).sorted { $0.lowercased() < $1.lowercased() }).map {(z : String) in SceneShaderLeaf(lib[z]!, group: id) }
  }()
}

struct SceneListView : View {
  var items : [SceneShaderLeaf]
  @AppStorage("selectedShader") var selit : String?

  var body: some View {
    List {
      ForEach( items, id: \.self ) { li  in
        NavigationLink(destination: SceneWrapperView(delegate: SKDelegate(shader: li)),
                       tag: li.id,
                       selection: $selit) {
          HStack {
            Text( li.myName ).frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }.frame(minWidth: 100, maxWidth: 400)
    }
  }
}

struct SceneSidebarView : View {
  var folderList : [SceneShaderLib]
  @State var selectedItem : String?

  var body: some View {
    Section(header: Text("Scenes")) {
      ForEach(folderList) {f in
        NavigationLink(destination: SceneListView(items: f.items)
                       , tag: f.id
                       , selection: $selectedItem ) {
          Text(f.libnam)
        }
      }
    }.listStyle(SidebarListStyle())
  }
}
