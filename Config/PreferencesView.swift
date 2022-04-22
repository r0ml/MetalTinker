
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

struct IdentifiableView : Identifiable {
  var id : String
  var view : AnyView
}

struct PreferencesView : View {
  var shader : GenericShader

  init(shdr: GenericShader) {
    self.shader = shdr
  }

/*  init(shader: T?) {
    config = shader?.config
  }*/

  var body: some View {
      List(shader.buildPrefView()) { ( x : IdentifiableView) in
        x.view
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
