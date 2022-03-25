
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

class FrameTimer : ObservableObject {
  @Published var shaderPlayerTime : String = ""
  @Published var shaderFPS : String = ""
}


class MetalDelegate<T : Shader> : NSObject, MTKViewDelegate, ObservableObject {
  var shader : T
  
  // Don't start out running
  @Published var isRunning : Bool = false
  
  var videoRecorder : MetalVideoRecorder?
  var times = Times()
  var frameTimer = FrameTimer()
  var fpsSamples : [Double] = Array(repeating: 1.0/60.0 , count: 60)
  var fpsX : Int = 0
  
//  var uniformBuffer : MTLBuffer!
  var setup = RenderSetup()
  var mySize : CGSize?
  
  let semCount = 1
  var gpuSemaphore : DispatchSemaphore = DispatchSemaphore(value: 1)
  
  init(shader: T) {
    self.shader = shader
  }
  
  // delegate
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    self.setup.mouseLoc = CGPoint(x: size.width / 2.0, y: size.height/2.0 )
    self.mySize = size;
  }
  
  func draw(in view: MTKView) {
//    shader.metalView = view
    
    if isRunning {
      
      // FIXME: sometimes I get trapped here!
      //      print("in gpusem", terminator: "" )
      let gw = gpuSemaphore.wait(timeout: .now() + .microseconds(1) /*    .microseconds(1000/60) */ )
      
      if gw == .timedOut {
        return }
      
      times.lastTime = times.currentTime
      times.currentTime = now()
      
      // calculate and display the Frames Per Second
      fpsSamples[fpsX] = times.currentTime - times.lastTime
      fpsX += 1
      if fpsX == fpsSamples.count { fpsX = 0 }
      let zz = fpsSamples.reduce(0, +)
      let t = Int(round(60.0 / zz))
      frameTimer.shaderFPS = String(t)
      
      
      // format the time for display
      let duration: TimeInterval = TimeInterval(times.currentTime - times.startTime)
      _ = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
      let d = Int(floor(duration))
      let seconds = d % 60
      let minutes = (d / 60) % 60
      let fd = String(format: "%0.2d:%0.2d", minutes, seconds); //   "%0.2d:%0.2d.%0.2d", minutes, seconds, ms)
      frameTimer.shaderPlayerTime = fd
      
      shader.setupFrame(times)
      shader.draw(in: view, delegate : self)
    }
  }
  
  
  // --------------------------
  
  func singleStep(metalView: MTKView) {
    // this should only work when I'm paused
    var paused = now() - times.lastTime;
    
    // single step backwards if shift key is pressed
    
#if os(macOS)
    let shifted = NSEvent.modifierFlags.contains(.shift)
#else
    let shifted = false
#endif
    
    if shifted {
      paused += (1/60.0)
      setup.iFrame -= 2;
    } else {
      paused -= (1/60.0)
    }
    times.startTime += paused
    times.lastTime += paused
    
    self.shader.draw(in: metalView, delegate : self)
  }
  
  func play() {
    times.currentTime = now()
    let paused = times.currentTime - times.lastTime
    times.startTime += paused
    times.lastTime += paused
    
    //   shader.config.videoNames.forEach { $0.start() }
    
    isRunning = true
    
    shader.startRunning() 
  }
  
  func stop() {
    isRunning = false
    shader.stopRunning()
    
    // config.webcam?.stopCapture()
    // config.videoNames.forEach { $0.pause() }
    
    NotificationCenter.default.removeObserver(self)
  }
  
  func rewind(_ sender : Any? = nil) {
    let n = now()
    times.lastTime = n
    times.currentTime = n
    times.startTime = n
    setup.iFrame = -1
  }
}
