
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

@main struct AppRender : App {

  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    Group {
      WindowGroup("MetalKit") {
        SidebarView().navigationTitle("AppRender Window")
      }
      .handlesExternalEvents(matching: ["appRender://metalkit"])
      .commands {
        SidebarCommands()
      }
    }
  }
}
