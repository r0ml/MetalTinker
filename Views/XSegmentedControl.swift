//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

import SwiftUI

struct XSegmentedControl : View {
  public var items : [MyMTLStruct] = []
  public var title : String = "no title"
  var pref : String

  @State var sel : Observable<Int>

  var body : some View {
    Picker( selection: $sel.x, label: Text(title)) {
      ForEach(0..<items.count) {
        Text(self.items[$0].name).tag($0)
      }
    }.pickerStyle( SegmentedPickerStyle() )
  }
  
/*  func pickone(_ z : Int) {
    UserDefaults.standard.set( z , forKey: pref )
    setPickS(sel.x, items)
  }
  
  func setPickS(_ a : Int, _ items : [MyMTLStruct] ) {
    for (i, tt) in items.enumerated() {
      tt.setValue( Int32(i == a ? 1 : 0) )
    }
  }*/
}

