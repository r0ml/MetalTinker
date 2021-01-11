
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI


struct XSlider : View {
  @ObservedObject var val : Observable<Double>
  
  var minVal : Double
  var maxVal : Double
  var pref : String
  var config : MyMTLStruct
  var isFloat : Bool
  
  func updateVal<T>(_ v : T) where T : BinaryFloatingPoint {
    UserDefaults.standard.set( v, forKey: self.pref)
    if self.isFloat {
      var py : SIMD3<Float> = self.config.value as! SIMD3<Float>
      py.y = Float(v)
      self.config.setValue( py)
    } else {
      var py : SIMD3<Int32> = self.config.value as! SIMD3<Int32>
      py.y = Int32(v)
      self.config.setValue(py)
    }
  }
  
  var body : some View {
    HStack {
      Text("\(config.name!) ( \(val.x) )")
      Slider(value: $val.x, in: minVal...maxVal, step: isFloat ? max(0.01, (maxVal - minVal) / 20) : 1)
    }
  }
}
