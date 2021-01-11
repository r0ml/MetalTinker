
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

struct IdentifiableView : Identifiable {
  var id : String
  var view : AnyView
}

struct PreferencesView: View {
  var config : ConfigController?

  init(scene: T3ShaderSCNScene?) {
    config = scene?.config
  }

  init(shader: Shader?) {
    config = shader?.config
  }

  var body: some View {
    if let c = self.config {
      List(c.buildPrefView()) { x in
        x.view
      }
    } else {
      EmptyView()
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
