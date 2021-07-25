// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

@main
struct MetalTinkerApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MetalTinkerDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
