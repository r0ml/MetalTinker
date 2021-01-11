
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import SwiftUI
import Combine
import SceneKit

var clem : NSWindow?

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
    v2.setFrameAutosaveName("SpriteKit Window")
    v2.contentView = NSHostingView(rootView: SpriteLibraryView())
    v2.makeKeyAndOrderFront(nil)
    v2.isReleasedWhenClosed = false
    clem2 = v
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
