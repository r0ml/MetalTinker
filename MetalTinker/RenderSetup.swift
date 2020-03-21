
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml

import AppKit
import MetalKit
import os

struct Uniform {
  var iDate : SIMD4<Float> = SIMD4<Float>(0,0,0,0)  // (year, month, day, time in seconds)
  var iMouse : SIMD2<Float> = SIMD2<Float>(0,0)     // mouse pixel coords
  var lastTouch : SIMD2<Float> = SIMD2<Float>(0,0)  // where the drag started (if buttons are down)
  var iResolution : SIMD2<Float> = SIMD2<Float>(0,0) // viewport resolution (in pixels)
  var keyPress : SIMD2<UInt32> = [0,0]         // the key which is down, and the key which was clicked
  var iFrame : Int32 = -1                      // shader playback frame
  var iTime : Float = 0                        // shader playback time (in seconds)
  var iTimeDelta : Float = Float(1)/Float(60)  // render time (in seconds)
  
  var mouseButtons : Int32 = 0;
  var eventModifiers : Int32 = 0;
}

class RenderSetup {
  var iFrame = -1
  var keyPress : SIMD2<UInt32> = [0,0]
  private var myName : String

  var textTextures : [MTLTexture?] = Array(repeating: nil, count: RenderManager.numberOfTexts)

  var mouseLoc : CGPoint = CGPoint(x: 800, y: 500)
  var lastTouch : CGPoint = CGPoint.zero
  var mouseButtons : Int = 0;

  init(_ n : String) {
    myName = n
  }


  // ===========================================================================================================
  // below the line here is stuff that happens on every frame
  
  
  /** Sets the values for the Uniform value passed to shaders.
   Needs to be called for every frame */
  public func setupUniform(size: CGSize, scale : Int, stat : Bool, uniform uni: MTLBuffer, times : Times) {
    let uniform = uni.contents().assumingMemoryBound(to: Uniform.self)
    
    if (!stat) {
      iFrame += 1

      let modifierFlags = NSEvent.modifierFlags
        //   let mouseButtons = NSEvent.pressedMouseButtons

      // Y coordinate on mouse needs to be flipped for Metal ?

     uniform.pointee.iMouse = SIMD2<Float>( Float(scale) * Float(mouseLoc.x) / Float(size.width), ( Float(size.height ) - Float(scale) *  Float(mouseLoc.y) ) / Float(size.height) )
     // uniform.pointee.iMouse = SIMD2<Float>( Float(scale) * Float(mouseLoc.x) / Float(size.width), Float(scale) *  Float(mouseLoc.y) / Float(size.height) )

     uniform.pointee.lastTouch = SIMD2<Float>( Float(scale) * Float(lastTouch.x) / Float(size.width), ( Float(size.height ) - Float(scale) *  Float(lastTouch.y) ) / Float(size.height) );
     // uniform.pointee.lastTouch = SIMD2<Float>( Float(scale) * Float(lastTouch.x) / Float(size.width), Float(scale) * Float(lastTouch.y) / Float(size.height) )

      // ,                                            Float(mouseButtons), Float(modifierFlags.rawValue) )
      uniform.pointee.mouseButtons = Int32(mouseButtons)
      uniform.pointee.eventModifiers = Int32(modifierFlags.rawValue)
    } else {
      uniform.pointee.iMouse = SIMD2<Float>(0.5, 0.5)
      uniform.pointee.mouseButtons = 0
      uniform.pointee.eventModifiers = 0
    }

    // Pass the key event in to the shader, then reset (so it only gets passed once)
    // when the key is released, event handling will so indicate.
    uniform.pointee.keyPress = self.keyPress
    self.keyPress.x = 0;

    // set resolution and time
    uniform.pointee.iFrame = Int32(iFrame)
    uniform.pointee.iResolution = SIMD2<Float>(Float(size.width), Float(size.height))
    uniform.pointee.iTime = Float(times.currentTime - times.startTime)
    uniform.pointee.iTimeDelta = Float(times.currentTime - times.lastTime)
    
    // Set up iDate
    let _date = Date()
    let components = Calendar.current.dateComponents( Set<Calendar.Component>([.year, .month, .day, .hour, .minute,  .second]), from:_date)
    let d = components.second! + components.minute! * 60 + components.hour! * 3600;
    let d2 = Float(d) + Float(_date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1));
    if let y = components.year, let m = components.month, let d = components.day {
      uniform.pointee.iDate = SIMD4<Float>(Float(y), Float(m), Float(d), d2)
    }

    // Done.  Sync with GPU
    uni.didModifyRange(0..<uni.length)
  }
  
}
