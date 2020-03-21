//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

import os
import SwiftUI

private struct MTLLibraryx : Identifiable  {
  var lib : MTLLibrary
  public var id : String {
    return lib.label!
  }
}

struct LibraryView : View {
  @ObservedObject var selection : Observable<String?>
  
  fileprivate let folderList : [MTLLibraryx] = {
    return metalLibraries.filter({ $0.label != "default"  }).sorted { $0.label!.lowercased() < $1.label!.lowercased() }.map { MTLLibraryx(lib: $0)}
  }()
  
  func getLib(_ f : MTLLibrary?) -> [RenderManager] {
    // FIXME: need some other way to identify the list of "shaders"
    if let ff = f {
      let res = ff.functionNames.compactMap { (nam) -> String? in
        var pnam : String
        if nam.hasSuffix("InitializeOptions") {
          pnam = String(nam.dropLast(17))
        } else {
          return nil
        }
        return pnam
      }

      return Set(res).sorted { $0.lowercased() < $1.lowercased() }.map { RenderManager($0) }
    } else {
      return []
    }
  }
  
  var thumbs : [NSImage] = [NSImage.init(named: "BrokenImage")!]
  
  func thisLib() -> [RenderManager] {
    if let l = selection.x,
      let lib = (folderList.first { l == $0.id }) {
      return getLib(lib.lib)
    } else {
      return []
    }
  }
  
  var body: some View {
    HSplitView( ) {
      ScrollView() {
        VStack.init(spacing: 0) {
          ForEach(self.folderList) { li in
            GeometryReader {g in
              Text(li.id).frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(EdgeInsets.init(top: 4, leading: 0, bottom: 4, trailing: 0))
            .background(
              li.id == self.selection.x ? Color(NSColor.lightGray) : Color.clear )
              .onTapGesture {
                // I need to force scrolling back to the top
                // or I get weird artifacts in the new selection values.
                // by 'unselecting' first, it resets
                self.selection.x = nil
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.03) {  self.selection.x = li.id }
            }
          }
        }
      }.frame(minWidth: 200, maxWidth: 400)
      
      GeometryReader {gg in
        List {
          ForEach( self.thisLib() ) { im in
            ShaderPreviewView(shader: im, pSize: CGSize(width: gg.size.width, height: gg.size.width * 9 / 16)).onTapGesture {
              if let w = (NSApp.delegate as! AppDelegate).shaderWindow {
                
                // Stop the old before setting the new
                let rs = (w.contentView as? NSHostingView<ShaderView>)?.rootView.shader
                rs?.stop()
                rs?.isRunning = false

                w.contentView = NSHostingView(rootView: ShaderView(message: Message(), shader: im))
                w.makeKeyAndOrderFront(nil)
              }
            }.frame(width: gg.size.width, height: gg.size.width * 9 / 16, alignment: .topLeading)
          }
        }
      }
    }
  }
}

struct LibraryView_Previews: PreviewProvider {
  static var sel = Observable<String?>("clem")
  static var previews: some View {
    LibraryView(selection: sel)
  }
}
