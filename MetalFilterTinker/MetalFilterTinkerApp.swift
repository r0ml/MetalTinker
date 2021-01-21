
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import SwiftUI
import Combine
import SceneKit

var clem : NSWindow?
var clem2 : NSWindow?

@main struct MetalFilterTinker : App {
  init() {
    let v = NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: 800, height: 400),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false)
    v.setFrameAutosaveName("SceneKit Window")
    v.contentView = NSHostingView(rootView: LibraryView())
    v.makeKeyAndOrderFront(nil)
    v.isReleasedWhenClosed = false
    clem = v

/*    let v2 = NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: 800, height: 400),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false)
    v2.setFrameAutosaveName("CIFilter Window")
    v2.contentView = NSHostingView(rootView: FilterLibraryView())
    v2.makeKeyAndOrderFront(nil)
    v2.isReleasedWhenClosed = false
    clem2 = v
*/

    /*
    let v3 = NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: 800, height: 400),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false)
    v3.setFrameAutosaveName("SpriteKit Window")
    v3.contentView = NSHostingView(rootView: SpriteLibraryView())
    v3.makeKeyAndOrderFront(nil)
    v3.isReleasedWhenClosed = false
    clem3 = v
*/


 }

  var body: some Scene {
    Group {
      WindowGroup {
        SceneLibraryView().navigationTitle("SceneKit Window")
      }
//      .commands {
//        MyCommands()
//      }
    }
  }
}
