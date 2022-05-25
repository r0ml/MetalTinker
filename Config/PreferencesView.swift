
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

struct IdentifiableView : Identifiable {
  var id : String
  var view : AnyView
}

struct PreferencesView : View {
  var shader : GenericShader?
  var scene : T1SCNScene?

  init(shdr: GenericShader) {
    self.shader = shdr
  }

  init(scene: T1SCNScene) {
    self.scene = scene
  }
/*  init(shader: T?) {
    config = shader?.config
  }*/

  var body: some View {
    if let shad = shader {
      List(shad.buildPrefView()) { ( x : IdentifiableView) in
        x.view
      }
    } else if let scen = scene {
      List(scen.buildPrefView()) { (x : IdentifiableView) in
        x.view
      }
    }
  }
  
  func buildView(types: [Any], index: Int) -> AnyView {
    switch types[index].self {
    default: return AnyView(EmptyView())
    }
  }
}

/*
 struct PreferencesView_Previews: PreviewProvider {
  static var previews: some View {
    PreferencesView( shader: Shader("clem") )
  }
}
*/
