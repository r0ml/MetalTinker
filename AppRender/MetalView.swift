
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

#if os(macOS)
typealias XViewController = NSViewController
typealias XViewControllerRepresentableContext = NSViewControllerRepresentableContext
#else
typealias XViewController = UIViewController
typealias XViewControllerRepresentableContext = UIViewControllerRepresentableContext
#endif

class MetalViewController<T : Shader> : XViewController {
  var mtkView : MTKView
  var delegate : MetalDelegate<T>
  var context : XViewControllerRepresentableContext<MetalViewC<T>>
  
  init( delegate: MetalDelegate<T>, context x: XViewControllerRepresentableContext<MetalViewC<T>>, mtkView mtkv : MTKView) {
    context = x
    mtkView = mtkv
    self.delegate = delegate
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    mtkView.preferredFramesPerSecond = 60
    
    #if os(macOS)
    mtkView.wantsLayer = true
    let ml = mtkView.layer!
    #else
    let ml = mtkView.layer
    #endif

    ml.backgroundColor = (context.environment.colorScheme == .dark ? XColor.darkGray : XColor.lightGray).cgColor
    ml.opacity = 1.0
    
    mtkView.sampleCount = multisampleCount
    mtkView.colorPixelFormat = thePixelFormat
    
    // depth stuff
    mtkView.depthStencilPixelFormat = .depth32Float
    mtkView.delegate = delegate
    mtkView.device = device
    mtkView.preferredFramesPerSecond = 60

    // If I don't do this, I can't debug
    mtkView.framebufferOnly = false

    self.view = mtkView
  }
  
  override func viewDidLoad() {
    // FIXME: how to do this in iOS
    #if os(macOS)
    NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .leftMouseDown, .leftMouseUp, .leftMouseDragged]) { ev in
      switch(ev.type) {
      case .leftMouseDown:
        let z = self.view.convert(ev.locationInWindow, from: nil)

        if self.view.isMousePoint(z, in: self.view.bounds) {
          self.delegate.setup.lastTouch = z
          self.delegate.setup.mouseButtons = 1
        }
      case .leftMouseUp:
        self.delegate.setup.lastTouch = CGPoint.zero
        self.delegate.setup.mouseButtons = 0
      case .leftMouseDragged:
        // print("dragging")
        // when keydown happens, I indicate that an event happened,
        // and that the key is down.  I expect that however uses the
        // key resets keyPress.x
        let _ = 0
      case .keyDown:
        if let t = ev.charactersIgnoringModifiers?.unicodeScalars.first {
          self.delegate.setup.keyPress = [t.value, t.value]
        }

        // when keyup happens, we're not holding keys
      case .keyUp:
//              if let t = ev.charactersIgnoringModifiers?.unicodeScalars.first {

//          if self.shader.setup.keyPress[0] == t.value {
        self.delegate.setup.keyPress = [0, 0]
//          }
//        }
      default:
        print("ignoring \(ev)")
      }
      return ev
    }
    #endif
  }
}

#if os(macOS)
struct MetalViewC : NSViewControllerRepresentable {
  typealias NSViewControllerType = MetalViewController
  var mtkView : MTKView = MTKView()
  var delegate : MetalDelegate

  func makeNSViewController(context: NSViewControllerRepresentableContext<MetalViewC>) -> MetalViewController {
    return MetalViewController( delegate: delegate, context: context, mtkView: mtkView)
  }
  
  func updateNSViewController(_ nsViewController: MetalViewController, context: NSViewControllerRepresentableContext<MetalViewC>) {
    // nsViewController.delegate.shader = self.shader
  }
}
#else
struct MetalViewC<T : Shader> : UIViewControllerRepresentable {
  typealias UIViewControllerType = MetalViewController
  var mtkView : MTKView = MTKView()
  var delegate : MetalDelegate<T>

  func makeUIViewController(context: UIViewControllerRepresentableContext<MetalViewC<T>>) -> MetalViewController<T> {
    return MetalViewController( delegate: delegate, context: context, mtkView: mtkView)
  }
  
  func updateUIViewController(_ uiViewController: MetalViewController<T>, context: UIViewControllerRepresentableContext<MetalViewC<T>>) {
    // uiViewController.delegate.shader = self.shader
  }
}

#endif

