
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#if os(macOS)
import AppKit
#endif

import MetalKit
import os

// FIXME: I have to get rid of the topology here -- it is controlled by the Shader class

struct ControlBuffer {
  var vertexCount : Int32;
  var instanceCount : Int32;
  var topology : Int32;
}

struct Uniform {
  var iDate : SIMD4<Float> = SIMD4<Float>(0,0,0,0)  // (year, month, day, time in seconds)
  var iMouse : SIMD2<Float> = SIMD2<Float>(0,0)     // mouse pixel coords
  var lastTouch : SIMD2<Float> = SIMD2<Float>(0,0)  // where the drag started (if buttons are down)
  var iResolution : SIMD2<Float> = SIMD2<Float>(0,0) // viewport resolution (in pixels)
  var keyPress : SIMD2<UInt32> = [0,0]         // the key which is down, and the key which was clicked
  var iFrame : Int32 = -1                      // shader playback frame
  var iTime : Float = 0                        // shader playback time (in seconds)
  var iTimeDelta : Float = Float(1)/Float(60)  // render time (in seconds)
  
  var mouseButtons : Int32 = 0
  var eventModifiers : Int32 = 0
}

struct RSetup {
  var keyPress : SIMD2<UInt32>
  var mouseLoc : CGPoint
  var lastTouch : CGPoint
  var mouseButtons : Int
  var mySize : CGSize?

//  var isRunning : Bool
//  var isStepping : Bool

  init(_ r : RenderSetup) async {
    keyPress = await r.keyPress
    mouseLoc = await r.mouseLoc
    lastTouch = await r.lastTouch
    mouseButtons = await r.mouseButtons
    mySize = await r.mySize
//    isRunning = await r.isRunning
//    isStepping = await r.isStepping
  }
}

// FIXME: make this an actor -- because when initializing a new shading render, vs setting up a frame
// from the previous render I get a data race.
// Contrariwise -- is there a way to make sure previous rendering is finished before switching the
// metal rendering engine.
actor RenderSetup {
  var keyPress : SIMD2<UInt32>
  
  var mouseLoc : CGPoint
  var lastTouch : CGPoint
  var mouseButtons : Int
  var mySize : CGSize?

//  var isRunning : Bool
//  var isStepping : Bool

  init() {
    keyPress = [0,0]
    mouseLoc = CGPoint(x: 800, y: 500)
    lastTouch = .zero
    mouseButtons = 0
//    isRunning = false
//    isStepping = false
  }

  init(_ j : RenderSetup) async {
    self.keyPress = await j.keyPress
    self.mouseLoc = await j.mouseLoc
    self.lastTouch = await j.lastTouch
    self.mouseButtons = await j.mouseButtons
    self.mySize = await j.mySize
//    self.isRunning = await j.isRunning
//    self.isStepping = await j.isStepping
  }

  public func setKeyPress( _ t : SIMD2<UInt32>) {
    keyPress = t
  }

  public func setMouseButtons(_ t : Int) {
    mouseButtons = t
  }

  // ===========================================================================================================
  // below the line here is stuff that happens on every frame
  

  func setTouch(_ t : CGPoint) {
    mouseLoc = t
  }

  func setLastTouch(_ t : CGPoint) {
    lastTouch = t
  }

  func resetKey() {
    self.keyPress.x = 0
  }

  func setSize( _ t : CGSize?) {
    mySize = t
  }

  /*
  func setStepping(_ t : Bool) {
    isStepping = t
  }

  func setRunning(_ t : Bool) {
    isRunning = t
  }
   */
}


extension RSetup {
  /** Sets the values for the Uniform value passed to shaders.
   Needs to be called for every frame */
  public func setupUniform(iFrame: Int, size: CGSize, scale : Int, uniform uni: MTLBuffer, times : Times) {
    let uniform = uni.contents().assumingMemoryBound(to: Uniform.self)

#if os(macOS)
    let modifierFlags = NSEvent.modifierFlags
    let mouseButtons = NSEvent.pressedMouseButtons
#endif

    let w = Float(size.width)
    let h = Float(size.height)
    let s = Float(scale)
    uniform.pointee.iMouse    = SIMD2<Float>( s * Float(mouseLoc.x)  / w, 1 - s * Float(mouseLoc.y) / h )
    uniform.pointee.lastTouch = SIMD2<Float>( s * Float(lastTouch.x) / w, 1 - s * Float(lastTouch.y) / h )
    uniform.pointee.mouseButtons = Int32(mouseButtons)

#if os(macOS)
    uniform.pointee.eventModifiers = Int32(modifierFlags.rawValue)
#endif

    // Pass the key event in to the shader, then reset (so it only gets passed once)
    // when the key is released, event handling will so indicate.
    uniform.pointee.keyPress = self.keyPress

    // set resolution and time
    uniform.pointee.iFrame = Int32(iFrame)
    uniform.pointee.iResolution = SIMD2<Float>(Float(size.width), Float(size.height))
    uniform.pointee.iTime = Float(times.currentTime - times.startTime)
    uniform.pointee.iTimeDelta = Float(times.currentTime - times.lastTime)

    // Set up iDate
    let _date = Date()
    let components = Calendar.current.dateComponents( Set<Calendar.Component>([.year, .month, .day, .hour, .minute,  .second]), from:_date)
    let d = components.second! + components.minute! * 60 + components.hour! * 3600;
    let d2 = Float(d) + Float(_date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1))
    if let y = components.year, let m = components.month, let d = components.day {
      uniform.pointee.iDate = SIMD4<Float>(Float(y), Float(m), Float(d), d2)
    }

    // Done.  Sync with GPU
    #if os(macOS) || targetEnvironment(macCatalyst)
    uni.didModifyRange(0..<uni.length)
    #endif
  }

}
