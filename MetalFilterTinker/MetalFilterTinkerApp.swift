
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import MetalKit
import SwiftUI
import Combine
import SceneKit


#if os(macOS)
var sceneWindow : NSWindow?
var spriteWindow : NSWindow?
var metalWindow : NSWindow?
#endif

// var clem : NSWindow?
// var clem2 : NSWindow?

@main struct AppRender : App {
    
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

  @Environment(\.scenePhase) private var scenePhase


  var body: some Scene {

    Group {
      WindowGroup("MetalKit") {
        ShaderLibraryView().navigationTitle("MetalKit Window")
      }
      .handlesExternalEvents(matching: ["appRender://metalkit"])
      .commands {
        SidebarCommands()
      }

      WindowGroup("SceneKit") {
        SceneLibraryView().navigationTitle("SceneKit Window").handlesExternalEvents(preferring: Set(arrayLiteral: "SceneKit"), allowing: Set(arrayLiteral: ""))
      }
      .handlesExternalEvents(matching: ["appRender://scenekit"])
//      .handlesExternalEvents(preferring: Set(arrayLiteral: "viewer"), allowing: Set(arrayLiteral: "*"))
        .commands {
//           CommandGroup(replacing: .newItem, addition: { })
        }

      // FIXME: put me back?
      #if os(macOS)
      WindowGroup("SpriteKit") {
        SpriteLibraryView().navigationTitle("SpriteKit Window")
      }
      .handlesExternalEvents(matching: ["appRender://spritekit","*"])
        .commands {
//           CommandGroup(replacing: .newItem, addition: { })
        }
      #endif

//      .commands {
//        MyCommands()
//      }
    }
  }
}
