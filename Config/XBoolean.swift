
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

struct XBoolean : View {
  var label: String = ""
  var pref : String = ""
  var config : MyMTLStruct
  
  @State var bool : Bool = false {
    didSet {
      print("set \(label)")
    }
  }
  
  func doStuff() -> Bool {
    UserDefaults.standard.set( bool, forKey: pref )
    config.setValue(bool)
    return true
  }
  
  var body : some View {
    Toggle(isOn: $bool) {
      doStuff() ? Text(label) : Text("not happening")
    }
    #if os(macOS)
    .toggleStyle( CheckboxToggleStyle() )
    #endif
  }
}
