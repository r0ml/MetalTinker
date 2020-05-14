
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Cocoa
import MetalKit
import SwiftUI

/** I need one instance of the GPU device.
 In the future, if I support multiple GPUs one day, this would need to change.
 */
let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.makeCommandQueue()!

@NSApplicationMain
public class AppDelegate: NSObject, NSApplicationDelegate {
  
  var shaderWindow : NSWindow?
  
  public func applicationDidFinishLaunching(_ aNotification: Notification) {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false)
    window.center()
    window.isReleasedWhenClosed = false
    window.setFrameAutosaveName("Metal Tinker")
    window.contentView = NSHostingView(rootView: LibraryView(selection: Observable<String?>( UserDefaults.standard.string(forKey: "librarySelection")) {
      z in
      UserDefaults.standard.set(z, forKey: "librarySelection" )
    }))
    window.makeKeyAndOrderFront(nil)
    
    // Quit when this menu window is closed
    NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: nil) {_ in
      NSApp.terminate(self)
    }
    
    shaderWindow = NSWindow(contentRect: NSRect(x:0, y:0, width: 480, height: 300),
                            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                            backing: .buffered, defer: false)
    shaderWindow?.center()
    shaderWindow?.isReleasedWhenClosed = false
    shaderWindow?.setFrameAutosaveName("Shader Window")
   }
  
  public func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  public func applicationShouldTerminateAfterLastWindowClosed(_ sender : NSApplication) -> Swift.Bool {
    return false
  }
  
  public func applicationWillResignActive(_ notification: Notification) {
  }

  public func applicationDidBecomeActive(_ notification: Notification) {
  }
}
