
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

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
}

