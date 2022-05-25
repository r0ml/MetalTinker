
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

/** This implements support for generating dynamic user interface for modifying shader preferences */
import os
import SwiftUI

fileprivate let LEFT_MARGIN = CGFloat(20)   // left edge of window
fileprivate let COLUMN_SPACING = CGFloat(10)   // gap between e.g. labels and text fields
fileprivate let LEFT_LABEL_WIDTH = CGFloat(70)   // width of all left labels
fileprivate let LINE_SPACING = CGFloat(10)   // leading between each line
fileprivate let FONT_SIZE = 17   // Magic hardcoded UITableView font size.

// let inputBufferReservedNames = ["vertexCount", "instanceCount", "topology"]

class DynamicPreferences {
//  private let config : ConfigController
  private let title : String
  
  init(_ title : String) { // _ sv : NSStackView) {
    self.title = title
//    self.config = config
  }
  
  func buildOptionsPane(_ bst : MyMTLStruct) -> [IdentifiableView] {
    guard let _ = bst.structure else {
      os_log("options buffer argument was not a struct", type: .error)
      return [ IdentifiableView(id: UUID().uuidString, view: AnyView(Text("options buffer argument was not a struct")))]
    }

    var res : [IdentifiableView] = []
    
    for bstm in bst.children {
      // let offs = bst.offset + bstm.offset
//      if inputBufferReservedNames.contains(bstm.name) { continue }


      let dnam = "\(self.title).\(bstm.name!)"
      // if this key already has a value, ignore the initialization value
      let dd =  UserDefaults.standard.object(forKey: dnam)
      
      if let _ = bstm.structure {
       // if bstm.name == "pipeline" { continue }
        // This is where segmented options happen
        let ddm = bstm.children;
        if let kk = ddm.first?.datatype, kk == .int || kk == .bool  {
          var v : Int = 0

          for (i, tt) in ddm.enumerated() {
            let z : Int? = tt.value as? Int
            if (z != 0) {
              v = i
              break
            }
          }


          let x = self.makeSegmented( bstm.name, dnam, ddm, value: (dd as? Int) ?? v)
          res.append( IdentifiableView(id: dnam, view: x) )

        }
      } else {
        
        let dat = bstm.value
        switch dat {
        case is Bool: // flag (checkbox)
          let x = self.makeBoolean(bstm.name, BoolParameter(mtl: bstm), value: dd as? Bool) // value: b)
          res.append( IdentifiableView(id: dnam, view: x) )
          
        case is SIMD4<Float>: // color (use a colorPicker)
          let v = dat as! SIMD4<Float>
          let cc = XColor.init(v)
          let x = self.makeColorPicker(bstm, value: cc)
          res.append( IdentifiableView(id: dnam, view: x) )
          
        case is SIMD3<Int32>: // integer slider (x and z are minimum and maximum values)
          let v = dat as! SIMD3<Int32>
          let x = self.makeNumberSlider(bstm, value: SIMD3<Float>(Float(v[0]), Float(v[1]), Float(v[2]) ), isFloat: false)
          res.append( IdentifiableView(id: dnam, view: x) )
          
        case is SIMD3<Float>: // floating point slider (x and z are minimum and maximum values)
          let v = dat as! SIMD3<Float>
          let x = self.makeNumberSlider(bstm, value: v, isFloat : true)
          res.append( IdentifiableView(id: dnam, view: x) )
          
        default:
          os_log("%s", type:.error, "\(bstm.name!) is \(bstm.datatype)")
        }
      }
    }
    return res
  }





  func buildOptionsPane(_ bst : Mirror) -> [IdentifiableView] {
/*    guard let _ = bst.structure else {
      os_log("options buffer argument was not a struct", type: .error)
      return [ IdentifiableView(id: UUID().uuidString, view: AnyView(Text("options buffer argument was not a struct")))]
    }
*/

    var res : [IdentifiableView] = []

    for bstm in bst.children {
      // let offs = bst.offset + bstm.offset
//      if inputBufferReservedNames.contains(bstm.name) { continue }


      let dnam = "\(self.title).\(bstm.label!)"
      // if this key already has a value, ignore the initialization value
      let dd =  UserDefaults.standard.object(forKey: dnam)

 /*     if let _ = bstm.structure {
       // if bstm.name == "pipeline" { continue }
        // This is where segmented options happen
        let ddm = bstm.children;
        if let kk = ddm.first?.datatype, kk == .int || kk == .bool  {
          var v : Int = 0

          for (i, tt) in ddm.enumerated() {
            let z : Int? = tt.value as? Int
            if (z != 0) {
              v = i
              break
            }
          }


          let x = self.makeSegmented( bstm.name, dnam, ddm, value: (dd as? Int) ?? v)
          res.append( IdentifiableView(id: dnam, view: x) )

        }
      } else {

   */     let dat = bstm.value
        switch dat {
        case is BoolParameter: // flag (checkbox)
          let x = self.makeBoolean(bstm.label!, dat as! BoolParameter, value: dd as? Bool) // value: b)
          res.append( IdentifiableView(id: dnam, view: x) )

/*
        case is SIMD4<Float>: // color (use a colorPicker)
          let v = dat as! SIMD4<Float>
          let cc = XColor.init(v)
          let x = self.makeColorPicker(bstm, value: cc)
          res.append( IdentifiableView(id: dnam, view: x) )
*/

/*
 case is IntParameter: // integer slider (x and z are minimum and maximum values)
          let v = dat as! IntParameter
          let x = self.makeNumberSlider(bstm, value: SIMD3<Float>(Float(v[0]), Float(v[1]), Float(v[2]) ), isFloat: false)
          res.append( IdentifiableView(id: dnam, view: x) )
*/

          /*
        case is FloatParameter: // floating point slider (x and z are minimum and maximum values)
          let v = dat as! FloatParameter
          let x = self.makeNumberSlider(bstm, value: v, isFloat : true)
          res.append( IdentifiableView(id: dnam, view: x) )
*/
        default:
          os_log("%s", type:.error, "\(bstm.label!) is \(type(of: bstm.value))")
        }
//      }
    }
    return res
  }









  private func makeColorPicker(_ arg : MyMTLStruct, value: XColor) -> AnyView {
    return AnyView(XColorPicker(value: value, label: arg.name, pref: "\(self.title).\(arg.name!)", config: arg, f: { _ in
      
      // FIXME: how do I set the clear color?
      /*
      if arg.name == "clearColor" {
        self.config.clearColor = $0.asFloat4()
      }
       */
    })
    )
  }
  
  private func makeBoolean(_ nam : String, _ arg : BoolParameter, value: Bool?) -> AnyView {
    let button =  XBoolean(label: nam, pref : "\(self.title).\(nam)", config: arg, bool: value ?? arg.getValue() )
    return AnyView(button)
  }

  private func makeSegmented( _ t:String, _ p:String, _ items : [MyMTLStruct], value: Int) -> AnyView {
    // first time in -- set the value
    for (i, tt) in items.enumerated() {
      tt.setValue( Int32(i == value ? 1 : 0) )
    }


    let sb = XSegmentedControl.init(items: items, title: t, pref: p, sel : Observable<Int>(value) {
      UserDefaults.standard.set($0, forKey: p)
      for (i, tt) in items.enumerated() {
        tt.setValue( Int32(i == $0 ? 1 : 0) )
      }
    })
    return AnyView(sb)
  }
  
  private func makeNumberSlider( _ arg : MyMTLStruct, value: SIMD3<Float>, isFloat : Bool ) -> AnyView {
    let of = Observable<Double>(Double(value.y))
    let slider = XSlider.init( val: of, minVal: Double(value.x), maxVal: Double(value.z),
                               pref: "\(self.title).\(arg.name!)", config: arg, isFloat: isFloat
    )
    // FIXME: ugly
    of.f = slider.updateVal
    return AnyView(slider)
  }

  /*
  private func makeNumberSlider( _ arg : Mirror.Child, value: FloatParameter, isFloat : Bool ) -> AnyView {
    let of = Observable<Double>(Double(value.val))
    let slider = XSlider.init( val: of, minVal: Double(value.low), maxVal: Double(value.high),
                               pref: "\(self.title).\(arg.name!)", config: arg.value as! FloatParameter, isFloat: isFloat
    )
    // FIXME: ugly
    of.f = slider.updateVal
    return AnyView(slider)
  }
*/


}

protocol ValueSettable {
  //  associatedtype VType
  func setValue<T>(_ x : T)
  func getValue<T>() -> T
}

extension MyMTLStruct : ValueSettable {
  typealias VType = Any
}

/*
class SettableValue : ValueSettable {
  var obj : AnyObject
  var lab : String

  init(_ s : String, _ o : AnyObject) {
    obj = o
    lab = s
  }

  func setValue(_ x : Any) {
    obj.setValue(x, forKey: lab)
  }
}
*/
