
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import os
import SwiftUI

struct FoldersListView<T : GenericShader> : View {
  var folders : [ShaderLib<T>]
  //  var initialSelection : String
  @State var selectedItem : String?
  var label : String
  
  init(_ s : String, folders: [ShaderLib<T>]) {  // }, selectedItem: Binding<String?>) {
    self.folders = folders
    self.label = s
    //    initialSelection = folders[2].id
    //    self._selectedItem = selectedItem
  }
  
  var body: some View {
    Section(header: Text(label)) {
      ForEach( folders ) { li in
        NavigationLink(destination: ShaderListView(items: li.items)
                       #if os(iOS) || targetEnvironment(macCatalyst)
                        .navigationBarTitle(li.id, displayMode: .inline)
                       #endif
                       ,
                       tag: li.id,
                       selection: $selectedItem) {
          HStack {
            Text(li.id).frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
  }
}

struct ShaderListView<T: GenericShader>: View {
  var items : [T]
  @AppStorage("selectedShader") var sel : String?
  
  var body: some View {
    List(selection: $sel) {
      ForEach( items ) { li  in
        NavigationLink(destination: ShaderMetalView(shader: li),
                       tag: li.id,
                       selection: $sel
        ) {
          HStack {
            Text( li.id ).frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }.frame(minWidth: 100, maxWidth: 400)
    }
  }
}
