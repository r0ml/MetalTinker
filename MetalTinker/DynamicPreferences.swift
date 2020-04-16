//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

/** This implements support for generating dynamic user interface for modifying shader preferences */
import AppKit
import os
import MetalKit
import SwiftUI

fileprivate let LEFT_MARGIN = CGFloat(20)   // left edge of window
fileprivate let COLUMN_SPACING = CGFloat(10)   // gap between e.g. labels and text fields
fileprivate let LEFT_LABEL_WIDTH = CGFloat(70)   // width of all left labels
fileprivate let LINE_SPACING = CGFloat(10)   // leading between each line
fileprivate let FONT_SIZE = 17   // Magic hardcoded UITableView font size.

class DynamicPreferences {
  private let config : ConfigController
  private let title : String
  
  init(_ title : String, _ config : ConfigController) { // _ sv : NSStackView) {
    self.title = title
    self.config = config
  }
  
  func buildOptionsPane(_ bst : MyMTLStruct) -> [IdentifiableView] {
    /*    guard let bstt = bst.structType() else {
     os_log("options buffer argument was not a struct", type: .error)
     return [ IdentifiableView(id: UUID().uuidString, view: AnyView(Text("options buffer argument was not a struct")))] }
     */
    var res : [IdentifiableView] = []
    
    for bstm in bst.children {
      // let offs = bst.offset + bstm.offset
      let dnam = "\(self.title).\(bstm.name!)"
      // if this key already has a value, ignore the initialization value
      let dd =  UserDefaults.standard.object(forKey: dnam)
      
      if let _ = bstm.structure {
        let ddm = bstm.children;
        
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

      } else {
        
        let dat = bstm.value
        switch dat {
        case is Bool:
          // let b : Bool = (dd as? Bool) ?? (dat as! Bool)
          let x = self.makeBoolean(bstm, value: dd) // value: b)
          res.append( IdentifiableView(id: dnam, view: x) )
          
        case is SIMD4<Float>:
          let v = dat as! SIMD4<Float>
          let cc = NSColor.init(calibratedRed: CGFloat(v[0]), green: CGFloat(v[1]), blue: CGFloat(v[2]), alpha: CGFloat(v[3]))
          let x = self.makeColorPicker(bstm, value: cc)
          res.append( IdentifiableView(id: dnam, view: x) )
          
        case is SIMD3<Int32>:
          let v = dat as! SIMD3<Int32>
          let x = self.makeNumberSlider(bstm, value: SIMD3<Float>(Float(v[0]), Float(v[1]), Float(v[2]) ), isFloat: false)
          res.append( IdentifiableView(id: dnam, view: x) )
          
        case is SIMD3<Float>:
          let v = dat as! SIMD3<Float>
          let x = self.makeNumberSlider(bstm, value: v, isFloat : true)
          res.append( IdentifiableView(id: dnam, view: x) )
          
          /*
           case .array:
           // this is the boundary???
           switch (bstm.arrayType()!.elementType) {
           case .array:
           os_log("two-D array", type:.debug)
           default:
           os_log("other array", type:.debug)
           }
           
           if bstm.arrayType()!.elementType == .char {
           os_log("%s", type: .debug, "\(bstm.name) is array of char")
           } else {
           os_log("%s", type:.debug, "\(bstm.name) is array of something else")
           }
           */
        default:
          os_log("%s", type:.error, "\(bstm.name!) is \(bstm.datatype)")
        }
      }
    }
    return res
  }
  
  func makeColorPicker(_ arg : MyMTLStruct, value: NSColor) -> AnyView {
    return AnyView(XColorPicker(value: value, label: arg.name, pref: "\(self.title).\(arg.name!)", config: arg))
    
  }
  
  public func makeBoolean(_ arg : MyMTLStruct, value: Any?) -> AnyView {
    let button =  XBoolean(label: arg.name, pref : "\(self.title).\(arg.name!)", config: arg, bool: value as? Bool ?? arg.value as! Bool)
    return AnyView(button)
  }
  
  func makeSegmented( _ t:String, _ p:String, _ items : [MyMTLStruct], value: Int) -> AnyView {
    let sb = XSegmentedControl.init(items: items, title: t, pref: p, sel : Observable<Int>(value) {
      UserDefaults.standard.set($0, forKey: p)
      for (i, tt) in items.enumerated() {
        tt.setValue( Int32(i == $0 ? 1 : 0) )
      }
    })
    return AnyView(sb)
  }
  
  public func makeNumberSlider( _ arg : MyMTLStruct, value: SIMD3<Float>, isFloat : Bool ) -> AnyView {
    let of = Observable<Double>(Double(value.y))
    let slider = XSlider.init( val: of, minVal: Double(value.x), maxVal: Double(value.z),
                               pref: "\(self.title).\(arg.name!)", config: arg, isFloat: isFloat
    )
    // FIXME: ugly
    of.f = slider.updateVal
    return AnyView(slider)
  }
}
