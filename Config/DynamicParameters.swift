// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation

class IntParameter : ValueSettable {
  var low : Int
  var val : Int
  var high : Int

  init(_ v : Int, range : Range<Int>) {
    val = v
    low = range.lowerBound
    high = range.upperBound
  }

  func setValue<T>(_ v : T) {
    val = v as! Int
  }

  func getValue<T>() -> T {
    return val as! T
  }
}

class FloatParameter : ValueSettable {
  var low : Float
  var val : Float
  var high : Float

  init(_ v : Float, range : Range<Float>) {
    val = v
    low = range.lowerBound
    high = range.upperBound
  }

  func setValue<T>(_ v : T) {
    val = v as! Float
  }

  func getValue<T>() -> T {
    return val as! T
  }
}

class BoolParameter : ValueSettable {

  var val : Bool?
  var mtl : MyMTLStruct?

  init(_ v : Bool) {
    val = v
  }

  init(mtl vx : MyMTLStruct) {
    mtl = vx
  }

  func setValue<T>(_ v : T) {
    if let mm = mtl {
      mm.setValue( v )
    } else {
      val = v as? Bool
    }
  }

  func getValue<T>() -> T {
    if let mm = mtl {
      return mm.getValue()
    } else {
      return val as! T
    }
  }
}
