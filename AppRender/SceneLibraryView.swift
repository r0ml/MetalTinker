
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

  public var id : String {
    if let k = rm as? T3ShaderSCNScene {
      return k.shaderName
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

  static let folderList : [SceneShaderLib] = {
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

struct SceneSidebarView : View {
  var folderList : [SceneShaderLib]

  var body: some View {
    Section(header: Text("Scenes")) {
      ForEach(folderList) {f in
        NavigationLink(destination: SceneListView(items: f.items) ) {
          Text(f.id)
        }
      }
    }.listStyle(SidebarListStyle())
  }
}
