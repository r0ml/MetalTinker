
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

struct ShaderMetalView : View {
  var shader : GenericShader
  @AppStorage("useMetalKit") var useMetalKit = false
  
/*  init(shader: GenericShader) {
    self.shader = shader
  }
  */
  
  var body : some View {
    let j =
        useMetalKit ? AnyView(MetalViewC(delegate: shader))
    : AnyView(ShaderSceneView(delegate: shader))
    VStack {
      VStack {
        j
#if os(macOS)
          .aspectRatio(1.4, contentMode: .fill)
#endif
          .onAppear {
            shader.play()
          }
          .onDisappear {
            shader.stop()
          }
        
        // The only reason I need the MTKView is in order to handle the single stepping (to manually call the draw
        // the other possibility is to short circuit the draw in the shader, and have the shader deal with single stepping
        ControlsView( frameTimer: shader.frameTimer, shader: shader /* , anyView: j.mtkView */ ).frame(minWidth: 300)
      }
      PreferencesView(shdr: shader)
    }
  }
}
