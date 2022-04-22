
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

struct ShaderView : View {
  var delegate : MetalDelegate
  
  var body : some View {
    let j = MetalViewC(delegate: delegate)
    VStack {
      VStack {
        j
#if os(macOS)
          .aspectRatio(1.4, contentMode: .fill)
#endif
          .onAppear {
            delegate.play()
          }
          .onDisappear {
            delegate.stop()
          }
        ControlsView( frameTimer: delegate.frameTimer, delegate: delegate, metalView: j.mtkView).frame(minWidth: 300)
      }
      PreferencesView(shdr: delegate.shader)
    }
  }
}
