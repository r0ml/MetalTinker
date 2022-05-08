// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import SceneKit
import MetalKit
import SwiftUI
import os

func now() -> Double {
  return Double ( DispatchTime.now().uptimeNanoseconds / 1000 ) / 1000000.0
}

struct Times {
  var currentTime : Double = now()
  var lastTime : Double = now()
  var startTime : Double = now()
}


// Renders a spritekit as the background for a SceneKit.  Hence, this is the same as just displaying the SpriteKit
class T3SCNScene : T1SCNScene {
  
  required init() {
    super.init()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var zoom : CGFloat = 1
  var dist : CGFloat = 0
  
  func zoom(_ n : CGFloat) {
    //    print("zoomed \(n)")
    zoom = n

    if self.rootNode.childNodes.count < 2 {
      // FIXME: don't know why this fails -- works on Simple4 -- fails on Simple6
      print("zoom failed")
    } else {
      self.rootNode.childNodes[1].position.z = XFloat(min(999, max(0.1, dist / max(n, 0.1))))
    }
    //    print("\(self.rootNode.childNodes[1].position.z)")
  }
  
  func updateZoom(_ n : CGFloat) {
    dist /= max(n, 0.1)
    dist = min(dist, 999)
    dist = max(dist, 0.01)
  }
}



