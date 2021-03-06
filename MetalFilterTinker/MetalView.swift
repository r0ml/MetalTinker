
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

class FrameTimer : ObservableObject {
  @Published var shaderPlayerTime : String = ""
  @Published var shaderFPS : String = ""
}

class MetalDelegate : NSObject, MTKViewDelegate, ObservableObject {
  var shader : Shader?
  // Don't start out running
  @Published var isRunning : Bool = false

  var videoRecorder : MetalVideoRecorder?
  var times = Times()
  var frameTimer = FrameTimer()
  var fpsSamples : [Double] = Array(repeating: 1.0/60.0 , count: 60)
  var fpsX : Int = 0
  private var syncQ = DispatchQueue(label: "synchronization q");

  var uniformBuffer : MTLBuffer!
  var setup = RenderSetup()
  var mySize : CGSize?

  static let semCount = 1
  var gpuSemaphore : DispatchSemaphore = DispatchSemaphore(value: semCount)


  // delegate

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    self.setup.mouseLoc = CGPoint(x: size.width / 2.0, y: size.height/2.0 )


    if self.mySize?.width != size.width || self.mySize?.height != size.height {
      // print("got a size update \(mySize) -> \(size)")
      // FIXME:
      // self.makeRenderPassTextures(size: size)
      self.shader?.config?.pipelinePasses.forEach { ($0 as? RenderPipelinePass)?.resize(size) }
    } else {
      // print("got a size update message when the size didn't change \(size)")
    }
    self.mySize = size;




//    shader?.mtkView(view, drawableSizeWillChange: size)
  }

  func draw(in view: MTKView) {
    shader?.metalView = view

    if isRunning {

      // FIXME: sometimes I get trapped here!
//      print("in gpusem", terminator: "" )
      let gw = gpuSemaphore.wait(timeout: .now() + .microseconds(1) /*    .microseconds(1000/60) */ )

      if gw == .timedOut {
        //        print("bailed")
//        print("...timed out")
        return }

//      print("... good to go")

   // syncQ.sync(flags: .barrier) {
      times.lastTime = times.currentTime
      times.currentTime = now()
   // }

    // calculate and display the Frames Per Second
    fpsSamples[fpsX] = times.currentTime - times.lastTime
    fpsX += 1
    if fpsX == fpsSamples.count { fpsX = 0 }
    let zz = fpsSamples.reduce(0, +)
    let t = Int(round(60.0 / zz))
    frameTimer.shaderFPS = String(t)


    // format the time for display
    let duration: TimeInterval = TimeInterval(times.currentTime - times.startTime)
    _ = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
    let d = Int(floor(duration))
    let seconds = d % 60
    let minutes = (d / 60) % 60
    let fd = String(format: "%0.2d:%0.2d", minutes, seconds); //   "%0.2d:%0.2d.%0.2d", minutes, seconds, ms)
    frameTimer.shaderPlayerTime = fd



      shader?.grabVideo(times)
      shader?.draw(in: view, delegate : self)
    }
  }


// --------------------------

  func singleStep(metalView: MTKView) {
    // this should only work when I'm paused
    var paused = now() - times.lastTime;

    // single step backwards if shift key is pressed
    if (NSEvent.modifierFlags.contains(.shift)) {
      paused += (1/60.0)
      setup.iFrame -= 2;
    } else {
      paused -= (1/60.0)
    }
    times.startTime += paused
    times.lastTime += paused

    self.shader?.draw(in: metalView, delegate : self)
  }

  func play() {
    times.currentTime = now()
    let paused = times.currentTime - times.lastTime
    times.startTime += paused
    times.lastTime += paused

    // shader?.config.videoNames.forEach { $0.start() }

    isRunning = true

    // shader?.config.webcam?.startCapture()
  }

  func stop() {
    isRunning = false

   // config.webcam?.stopCapture()
   // config.videoNames.forEach { $0.pause() }

    NotificationCenter.default.removeObserver(self)
  }

  func rewind(_ sender : Any? = nil) {
    let n = now()
    times.lastTime = n
    times.currentTime = n
    times.startTime = n
    setup.iFrame = -1
  }




}

class MetalViewController : NSViewController {
  var mtkView : MTKView
  var delegate : MetalDelegate
  var context : NSViewControllerRepresentableContext<MetalViewC>
  
  init( delegate: MetalDelegate, context x: NSViewControllerRepresentableContext<MetalViewC>, mtkView mtkv : MTKView) {
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
    mtkView.wantsLayer = true

    mtkView.layer?.backgroundColor = (context.environment.colorScheme == .dark ? NSColor.darkGray : NSColor.lightGray).cgColor

    mtkView.layer?.opacity = 1.0
    mtkView.sampleCount = multisampleCount
    mtkView.colorPixelFormat = thePixelFormat
    
    // depth stuff
    mtkView.depthStencilPixelFormat = .depth32Float

 //   shader.resetTarget( mtkView )

    mtkView.delegate = delegate

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
  }
}

struct MetalViewC : NSViewControllerRepresentable {
  typealias NSViewControllerType = MetalViewController
  // @ObservedObject var shader : Shader
  var mtkView : MTKView = MTKView()
  var delegate : MetalDelegate

  func makeNSViewController(context: NSViewControllerRepresentableContext<MetalViewC>) -> MetalViewController {
    return MetalViewController( delegate: delegate, context: context, mtkView: mtkView)
  }
  
  func updateNSViewController(_ nsViewController: MetalViewController, context: NSViewControllerRepresentableContext<MetalViewC>) {
    // nsViewController.delegate.shader = self.shader
  }
}
