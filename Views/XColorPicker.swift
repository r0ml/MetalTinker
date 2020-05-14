
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

// I need to hang this somewhere to prevent it from being garbage collected
var colorUpdater : XColorPicker.ColorUpdater? = nil

struct XColorPicker : View {
  @State var value : NSColor
  var label : String
  var pref : String
  var config : MyMTLStruct
  
  class ColorUpdater {
    var bufferMem : UnsafeMutablePointer<SIMD4<Float>>
    var key : String
    var bv : Binding<NSColor>
    
    init(_ j : UnsafeMutablePointer<SIMD4<Float>>, _ v : Binding<NSColor>, _ k : String) {
      bufferMem = j
      key = k
      bv = v
    }
    
    @objc func colorDidChange(_ sender: AnyObject) {
      if let cp = sender as? NSColorPanel {
        bufferMem.pointee = cp.color.asFloat4()
        bv.wrappedValue = cp.color
        bv.update()
        UserDefaults.standard.set( cp.color, forKey: key )
      }
    }
  }
  
  var body : some View {
    Button(action: {
      let cp = NSColorPanel.shared
      let cu : UnsafeMutablePointer<SIMD4<Float>> = self.config.getBufPtr()
      let j = ColorUpdater(cu, self.$value, self.pref )
      colorUpdater = j
      cp.setTarget(j)
      cp.setAction(#selector(ColorUpdater.colorDidChange(_:)))
      cp.makeKeyAndOrderFront(self)
      cp.showsAlpha = true
      cp.isContinuous = true
    }) {
      ZStack() {
        Text(label)
        Color(value).frame(width: 15, height: 15)
      }
    }
  }
}

