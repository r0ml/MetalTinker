
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

struct ControlsView: View {
  // @ObservedObject var shader : Shader
  @ObservedObject var frameTimer : FrameTimer
  @ObservedObject var delegate : MetalDelegate
  var metalView : MTKView

  var body: some View {
    HStack.init(alignment: .center, spacing: 20) {
      Image( "rewind", bundle: nil, label: Text("Rewind")).resizable().scaledToFit()
        .frame(width: 64, height: 64).onTapGesture {
          self.delegate.rewind()
      }

      if self.delegate.isRunning {
        Image("pause", bundle: nil, label: Text("Pause")).resizable().scaledToFit()
          .frame(width: 64, height: 64).onTapGesture {
            self.delegate.stop()
        }
      } else {
        HStack() {
          Image("play", bundle: nil, label: Text("Play")).resizable().scaledToFit()
            .frame(width: 64, height: 64).onTapGesture {
              self.delegate.play()
          }
          
          Image("single_step").resizable().scaledToFit()
            .frame(width: 64, height: 64).onTapGesture {
              self.delegate.singleStep(metalView: metalView)
              
          }
        }
      }
      Spacer()
      
      Text(frameTimer.shaderPlayerTime)
      Text(frameTimer.shaderFPS)
      
      Spacer()

      // FIXME: change this to use SwiftUI version of Save panel
      #if os(macOS)
      Image("camera", bundle: nil, label: Text("Snapshot")).resizable().scaledToFit()
        .frame(width: 64, height: 64).onTapGesture {
          let lastDrawableDisplayed = self.metalView.currentDrawable?.texture
          
          if let ldd = lastDrawableDisplayed,
            let imageOfView = CIImage.init(mtlTexture: ldd, options: nil)?.nsImage {
          //  let imageOfView = NSImage.init(cgImage: imageRef, size: CGSize(width: imageRef.width, height: imageRef.height))

            // FIXME:  The metal keeps updating while the save panel is up.
            //   should it stop during the snapshot?
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = true
            savePanel.nameFieldStringValue = "\(self.delegate.shader.myName).png"
            savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
            savePanel.begin { (result) in
              if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                imageOfView.writePNG(toURL: savePanel.url!)
              }
            }
          }
          
      }
      #endif

      Image("videocam", bundle: nil, label: Text("Record")).resizable().scaledToFit()
        .frame(width:64, height: 64).onTapGesture {
          if let v = self.delegate.videoRecorder {
            v.endRecording {
              print("recording ended")
            }
            self.delegate.videoRecorder = nil
          } else {
            
            let directory = NSTemporaryDirectory()
            let fileName = NSUUID().uuidString
            // This returns a URL? even though it is an NSURL class method
            let fullURL = NSURL.fileURL(withPathComponents: [directory, fileName])
            
            print(fullURL!.absoluteURL)
            
            self.delegate.videoRecorder = MetalVideoRecorder(outputURL: fullURL!, size: self.metalView.drawableSize)
            self.delegate.videoRecorder?.startRecording()
            // os_log("videocam click not implemented yet", type: .debug)
          }
      }
      
    }.frame(minWidth: 600, minHeight: 70)
  }
}

