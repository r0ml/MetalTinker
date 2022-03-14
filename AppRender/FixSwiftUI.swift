
//  Created by Robert Lefkowitz on 1/30/22.
//  Copyright © 2022 Semasiology. All rights reserved.

import SwiftUI

#if os(iOS) || targetEnvironment(macCatalyst)

struct UIKitShowSidebar: UIViewRepresentable {
    let onScreen: Bool

    func makeUIView(context: Context) -> some UIView {
        let uiView = UIView()
        
        if self.onScreen {
          Task { await MainActor.run { [weak uiView] in
                uiView?.next(
                    of: UISplitViewController.self
                )?.show(.primary)
            }
          }
        }
        
        return uiView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.async { [weak uiView] in
            uiView?.next(
                of: UISplitViewController.self
            )?.show(.primary)
        }
    }
}

extension UIResponder {
    func next<T>(of type: T.Type) -> T? {
        guard let nextValue = self.next else {
            return nil
        }
        guard let result = nextValue as? T else {
            return nextValue.next(of: type.self)
        }
        return result
    }
}
#endif

struct NothingSelectedView: View {
    
    #if canImport(UIKit)
    @State
    var onScreen: Bool = false
    #endif
    
    var body: some View {
        Label(
            "Nothing Selected",
            systemImage: "exclamationmark.triangle"
        )

        #if canImport(UIKit)
        UIKitShowSidebar(onScreen: onScreen).frame(
            width: 0,
            height: 0
        ).onAppear {
            onScreen = true
        }.onDisappear {
            onScreen = false
        }
        #endif
    }
}

