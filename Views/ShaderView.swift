
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

struct ShaderView: View {
  @ObservedObject var message : Message
  @ObservedObject var shader : RenderManager
  
  var mtv : MetalViewC
  
  
  init(message: Message, shader: RenderManager) {
    self.message = message
    self.shader = shader
    self.mtv = MetalViewC(shader: shader)
  }
  
  var body: some View {
    HSplitView() {
      VStack {
      GeometryReader { g in
        VStack() {
          TextField("Message", text: self.$message.msg).disabled(true)
          Text(self.shader.myName)
          self.mtv.frame(minWidth: 400, idealWidth: 800, maxWidth: 3200, minHeight: 225, idealHeight: 450, maxHeight: 1800, alignment: .top)
            .aspectRatio(16/9.0, contentMode: .fit).layoutPriority(101.0)
            .onAppear(perform: {
              self.shader.isRunning = true
              self.shader.rewind()
              self.shader.play()
//              self.message.msg = "Ready"
            }).onDisappear(perform: {
              self.shader.isRunning = false
              self.shader.stop()
            })
          ControlsView(shader: self.shader, frameTimer: self.shader.frameTimer, metalView: self.mtv.mtkView                                                      ).frame(minWidth: g.size.width)
          PreferencesView(shader: self.shader )
        }
      }.frame(minWidth: 600)
      }.layoutPriority(105);
      }
  }
}


struct ShaderView_Previews: PreviewProvider {
  @ObservedObject static var shader = RenderManager("clem")
  @ObservedObject static var msg = Message()
  static var previews: some View {
    ShaderView(message: msg, shader: shader)
  }
}
