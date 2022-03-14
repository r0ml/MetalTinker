
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

struct SceneControlsView: View {
  var scene : T1SCNScene

  @Binding var paused : Bool

  var body: some View {
    if paused != self.scene.isPaused {
      Task {
        await MainActor.run { paused = self.scene.isPaused }
      }
    }
    return HStack.init(alignment: .center, spacing: 20) {
      Image( "rewind", bundle: nil, label: Text("Rewind")).resizable().scaledToFit()
        .frame(width: 64, height: 64).onTapGesture {
         // self.delegate.rewind()
          print("rewind is not implemented")
      }

      if !self.paused {
        Image("pause", bundle: nil, label: Text("Pause")).resizable().scaledToFit()
          .frame(width: 64, height: 64).onTapGesture {
            self.scene.pause(true)

//            (self.scene as? T3SCNScene)?.rootNode.childNodes[1].isPaused = true
//            (self.scene as? SKSCNScene)?.skScene.isPaused = true
            
            self.paused.toggle()
        }
      } else {
        HStack() {
          Image("play", bundle: nil, label: Text("Play")).resizable().scaledToFit()
            .frame(width: 64, height: 64).onTapGesture {
              self.scene.pause(false)
              self.paused.toggle()
          }

          Image("single_step").resizable().scaledToFit()
            .frame(width: 64, height: 64).onTapGesture {
           //   self.delegate.singleStep(metalView: metalView)
              print("single stepping is not implemented")
          }
        }
      }
      Spacer()

  //    Text(frameTimer.shaderPlayerTime)
  //    Text(frameTimer.shaderFPS)

      Spacer()

      Image("camera", bundle: nil, label: Text("Snapshot")).resizable().scaledToFit()
        .frame(width: 64, height: 64).onTapGesture {
          print("camera is not implemented yet")
          /*
          let lastDrawableDisplayed = self.metalView.currentDrawable?.texture

          if let ldd = lastDrawableDisplayed,
            let imageOfView = CIImage.init(mtlTexture: ldd, options: nil)?.nsImage {
          //  let imageOfView = NSImage.init(cgImage: imageRef, size: CGSize(width: imageRef.width, height: imageRef.height))

            // FIXME:  The metal keeps updating while the save panel is up.
            //   should it stop during the snapshot?
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = true
            savePanel.nameFieldStringValue = "\(self.delegate.shader?.myName).png"
            savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
            savePanel.begin { (result) in
              if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                imageOfView.writePNG(toURL: savePanel.url!)
              }
            }
          } */

      }

      Image("videocam", bundle: nil, label: Text("Record")).resizable().scaledToFit()
        .frame(width:64, height: 64).onTapGesture {
          print("videocam is not implemented yet")
/*
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
 */
      }

    }.frame(minWidth: 600, minHeight: 70)
  }
}

