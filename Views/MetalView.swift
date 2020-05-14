
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

class MetalViewController : NSViewController {
  var mtkView : MTKView
  var shader : RenderManager
  var context : NSViewControllerRepresentableContext<MetalViewC>
  
  init(shader s: RenderManager, context x: NSViewControllerRepresentableContext<MetalViewC>, mtkView mtkv : MTKView) {
    shader = s
    context = x
    mtkView = mtkv
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    mtkView.preferredFramesPerSecond = 60
    mtkView.wantsLayer = true
    
    mtkView.layer?.backgroundColor = (context.environment.colorScheme == .dark ? NSColor.darkGray : NSColor.lightGray).cgColor

    mtkView.layer?.opacity = 1.0
    mtkView.sampleCount = multisampleCount
    mtkView.colorPixelFormat = thePixelFormat
    
    // depth stuff
    mtkView.depthStencilPixelFormat = .depth32Float
    
    shader.resetTarget( mtkView )
    
    mtkView.device = device
    mtkView.preferredFramesPerSecond = 60

    // If I don't do this, I can't debug
    mtkView.framebufferOnly = false
    self.view = mtkView
  }
  
  override func viewDidLoad() {
    NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .leftMouseDown, .leftMouseUp, .leftMouseDragged]) { ev in
      switch(ev.type) {
      case .leftMouseDown:
        let z = self.view.convert(ev.locationInWindow, from: nil)

        if self.view.isMousePoint(z, in: self.view.bounds) {
          self.shader.setup.lastTouch = z
          self.shader.setup.mouseButtons = 1
        }
      case .leftMouseUp:
        self.shader.setup.lastTouch = CGPoint.zero
        self.shader.setup.mouseButtons = 0
      case .leftMouseDragged:
        // print("dragging")
        // when keydown happens, I indicate that an event happened,
        // and that the key is down.  I expect that however uses the
        // key resets keyPress.x
        let _ = 0
      case .keyDown:
        if let t = ev.charactersIgnoringModifiers?.unicodeScalars.first {
          self.shader.setup.keyPress = [t.value, t.value]
        }

        // when keyup happens, we're not holding keys
      case .keyUp:
//              if let t = ev.charactersIgnoringModifiers?.unicodeScalars.first {

//          if self.shader.setup.keyPress[0] == t.value {
            self.shader.setup.keyPress = [0, 0]
//          }
//        }
      default:
        print("ignoring \(ev)")
      }
      return ev
    }
  }
}

struct MetalViewC : NSViewControllerRepresentable {
  typealias NSViewControllerType = MetalViewController
  @ObservedObject var shader : RenderManager
  var mtkView : MTKView = MTKView()
  
  func makeNSViewController(context: NSViewControllerRepresentableContext<MetalViewC>) -> MetalViewController {
    return MetalViewController(shader: shader, context: context, mtkView: mtkView)
  }
  
  func updateNSViewController(_ nsViewController: MetalViewController, context: NSViewControllerRepresentableContext<MetalViewC>) {
  }
}
