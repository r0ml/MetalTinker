
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

class Choice : Identifiable {
  typealias ObjectIdentifier = Int
  var id : ObjectIdentifier
  var obj : MyMTLStruct

  init(_ z : (Int, MyMTLStruct)) {
    self.id = z.0
    self.obj = z.1
  }
}

struct XSegmentedControl : View {
  public var items : [MyMTLStruct] = []
  public var title : String = "no title"
  var pref : String

  @State var sel : Observable<Int>

  var body : some View {
    Picker( selection: $sel.x, label: Text(title)) {
      ForEach(items.enumerated().map { Choice($0) }) {
        Text($0.obj.name).tag($0.id)
      }
    }.pickerStyle( SegmentedPickerStyle() )
  }
}

