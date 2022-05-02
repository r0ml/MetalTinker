
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

/* TODO:
 1) Add custom application activity for macCatalyst to save to file
 2) reposition the menu for macCatalyst (and maybe iOS)
 */
struct ControlsView : View {
  // @ObservedObject var shader : Shader
  @ObservedObject var frameTimer : FrameTimer
  @ObservedObject var shader : GenericShader

  #if os(iOS)
  func shareSheet(image: UIImage) {
      let activityView = UIActivityViewController(activityItems: [image], applicationActivities: nil)

    if let ww = UIApplication.shared.connectedScenes
      .filter({$0.activationState == .foregroundActive})
      .compactMap({$0 as? UIWindowScene})
      .first?.windows
      .filter({$0.isKeyWindow}).first {


      if let popoverController = activityView.popoverPresentationController {
          popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
        popoverController.sourceView = self.metalView
          popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
      }



  //    activityView.popoverPresentationController?.sourceView = ww
      ww.rootViewController?.present(activityView, animated: true, completion: nil)
    }

/*
      let allScenes = UIApplication.shared.connectedScenes
      let scene = allScenes.first { $0.activationState == .foregroundActive }

      if let windowScene = scene as? UIWindowScene {
          windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
      }
 */

// FIXME: for macCatalyst??

/*
    let fileManager = FileManager.default

    do {
        let fileURL2 = fileManager.temporaryDirectory.appendingPathComponent("\(detailedList.lname!).json")

        // Write the data out into the file
        try jsonData.write(to: fileURL2)

        // Present the save controller. We've set it to `exportToService` in order
        // to export the data -- OLD COMMENT
        let controller = UIDocumentPickerViewController(url: fileURL2, in: UIDocumentPickerMode.exportToService)
        present(controller, animated: true) {
            // Once we're done, delete the temporary file
            try? fileManager.removeItem(at: fileURL2)
        }
    } catch {
        print("error creating file")
    }

*/


  }
#endif

  var body: some View {
    
    HStack.init(alignment: .center, spacing: 20) {
      Image( "rewind", bundle: nil, label: Text("Rewind")).resizable().scaledToFit()
        .frame(width: 64, height: 64).onTapGesture {
          self.shader.rewind()
      }

      if self.shader.isRunningx {
        Image("pause", bundle: nil, label: Text("Pause")).resizable().scaledToFit()
          .frame(width: 64, height: 64).onTapGesture {
            self.shader.stop()
        }
      } else {
        HStack() {
          Image("play", bundle: nil, label: Text("Play")).resizable().scaledToFit()
            .frame(width: 64, height: 64).onTapGesture {
              self.shader.play()
          }
          
          Image("single_step").resizable().scaledToFit()
            .frame(width: 64, height: 64).onTapGesture {
              self.shader.singleStep()
              
          }
        }
      }
      Spacer()
      
      Text(frameTimer.shaderPlayerTime)
      Text(frameTimer.shaderFPS)
      
      Spacer()

      // FIXME: change this to use SwiftUI version of Save panel
      #if os(macOS)
      
      /*
      Image("camera", bundle: nil, label: Text("Snapshot")).resizable().scaledToFit()
        .frame(width: 64, height: 64).onTapGesture {
          let lastDrawableDisplayed = metalView.currentDrawable?.texture
          
          if let ldd = lastDrawableDisplayed,
            let imageOfView = CIImage.init(mtlTexture: ldd, options: nil)?.nsImage {
          //  let imageOfView = NSImage.init(cgImage: imageRef, size: CGSize(width: imageRef.width, height: imageRef.height))

            // FIXME:  The metal keeps updating while the save panel is up.
            //   should it stop during the snapshot?
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = true
            savePanel.nameFieldStringValue = "\(self.shader.myName).png"
            savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
            savePanel.begin { (result) in
              if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                imageOfView.writePNG(toURL: savePanel.url!)
              }
            }
          }
          
      }
       */
      #else
      Image("camera", bundle: nil, label: Text("Snapshot")).resizable().scaledToFit()
        .frame(width: 64, height: 64).onTapGesture {

          let lastDrawableDisplayed = self.metalView.currentDrawable?.texture

          if let ldd = lastDrawableDisplayed,
             let ci = CIImage.init(mtlTexture: ldd, options: nil) {
              let x = UIImage(ciImage: ci)
            shareSheet(image: x)
          }
        }
      #endif


      Image("videocam", bundle: nil, label: Text("Record")).resizable().scaledToFit()
        .frame(width:64, height: 64).onTapGesture {
          if let v = self.shader.videoRecorder {
            v.endRecording {
              print("recording ended")
            }
            self.shader.videoRecorder = nil
          } else {
            // FIXME: put me back
 /*
            let directory = NSTemporaryDirectory()
            let fileName = NSUUID().uuidString
            // This returns a URL? even though it is an NSURL class method
            let fullURL = NSURL.fileURL(withPathComponents: [directory, fileName])
            
            print(fullURL!.absoluteURL)
            
            self.shader.videoRecorder = MetalVideoRecorder(outputURL: fullURL!, size: metalView.drawableSize)
            self.shader.videoRecorder?.startRecording()
            // os_log("videocam click not implemented yet", type: .debug)
  */
          }
      }
      
    }.frame(minWidth: 600, minHeight: 70)
  }
}

