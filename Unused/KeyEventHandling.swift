// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI

#if os(macOS)

class Clem {
  var view : NSView?
}

struct KeyEventHandling: NSViewRepresentable {
  var fn : (NSEvent) -> ()
  var name : String
  @State var hasFocus : Bool = false

  class KeyView : NSView {
    var fn : (NSEvent) -> ()
    init(_ f : @escaping (NSEvent)-> () ) {
      self.fn = f
      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event : NSEvent) {
      // super.keyDown(with: event)
      fn(event) // print(">> key \(event.charactersIgnoringModifiers ?? "")")
    }
  }

  init(_ n : String, _ f : @escaping (NSEvent)->() ) {
    self.fn = f
    self.name = n
  }

  func focus() {
    NotificationCenter.default.post(Notification(name: Notification.Name("focus"), object: name ) )
  }
  
  func makeNSView(context : Context) -> NSView {
    let v = KeyView(fn)
    NotificationCenter.default.addObserver(forName: Notification.Name("focus"), object: name, queue: nil) { _ in
//      let b = v.becomeFirstResponder()
      let _ = v.window?.makeFirstResponder(v)
//      print("get focus \(self.name): \(b)")
    }
    DispatchQueue.main.async {
      v.window?.makeFirstResponder(v)
    }
  //  print("set \(name) view to keyview")
    return v
  }

  func updateNSView(_ nsView : NSView, context: Context) {

  }
}

#endif
