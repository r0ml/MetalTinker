
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import UniformTypeIdentifiers
import MetalKit
import AVFoundation
import os

struct ImageStrip : View {
  @Binding var texes : [TextureParameter]

  // This is to force redrawing the ImageStrip when one of the images changes
  @State var uuid = UUID()

  func menu( _ jj : Int ) -> some View {
    return VStack {
      ForEach(CameraPicker.cameraList, id: \.self) { n in
      Button(action: {
        let z = WebcamSupport(camera: n)
        z.startVideo()
        texes[jj].video = z // WebcamSupport()
        texes[jj].image = XImage(named: "webcam_still")!
//               texes[jj.id].texture = z.frameTexture
        uuid = UUID()

      } ) {
        Text(n)
      }
      }
      Button(action: {
        print("open file")
      }) {
        Text("Open File")
      }
    }
  }

  var body : some View {
    HStack {

      // FIXME:  if the old 'image' was the webcam, shut it off
      // alternatively -- always shut off the webcam, and restart it if it is still there.
      ForEach(texes) { (jj) in

        // FIXME: i windws up out of range -- must be from resetting texes
        AnyView(Image.init(xImage: jj.image).resizable()
          .scaledToFit())
        .contextMenu(menuItems: {
          menu(jj.id)
        })

          .onDrop(of: [UTType.fileURL, UTType.text, UTType.utf8PlainText, UTType.image, UTType.video, UTType.movie], isTargeted: nil, perform: { (y) in

            //          var sem = DispatchSemaphore(value: 0)

            //          DispatchQueue.global().async {
            /*          y[0].loadItem(forTypeIdentifier: UTType.image.identifier, options: nil ) {
             (im, error) in
             print(im)
             print(error)
             }

             */

            if y[0].canLoadObject(ofClass: AVURLAsset.self) {
              y[0].loadObject(ofClass: AVURLAsset.self) {
              (x, r) in
              if let e = r {
                print(e.localizedDescription)
                return
              }
              if let v = x as? AVURLAsset {
                print("avurlasset?")
              }
            }
              return true
            }

            #if !os(macOS)

            if y[0].canLoadObject(ofClass: XImage.self) {

            y[0].loadObject(ofClass: XImage.self) { (x, r) in
              if let e = r {
                print(e.localizedDescription)
                return
              }
              if let im = x as? XImage {
                texes[jj.id].image = im
                texes[jj.id].texture = im.getTexture(MTKTextureLoader(device: device))
                uuid = UUID()
              }
            }
              return true
            }
            #endif

            if y[0].canLoadObject(ofClass: NSURL.self) {
            y[0].loadObject(ofClass: NSURL.self) { (urlData, error) in
              if let e = error {
                print(e.localizedDescription)
                return
              }

              if let j = urlData as? URL {
                // FIXME: Fix this on StackOverflow
                do {
                  let bmd = try j.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                  UserDefaults.standard.set(bmd, forKey: "texture\(jj.id)")  // should it be index instead of id?
                } catch(let e ) {
                  os_log("failed to store URL for texture %s", e.localizedDescription)
                }

                let uti = UTType.types(tag: j.pathExtension, tagClass: UTTagClass.filenameExtension, conformingTo: UTType.data)
                /*            let uti = UTTypeCreatePreferredIdentifierForTag(
                 kUTTagClassFilenameExtension,
                 j.pathExtension as CFString,
                 nil)
                 let utix = uti?.takeRetainedValue()
                 */

                // FIXME: bring it back for iOS
                #if os(macOS)
                if uti[0].conforms(to: UTType.image) {
                  if let k = XImage.init(contentsOf: j) {
                    texes[jj.id].image = k
                    texes[jj.id].texture = k.getTexture(MTKTextureLoader(device: device))
                    uuid = UUID()
                  }
                } else if uti[0].conforms(to: .movie) {
                  let vs = VideoSupport(url: j)
                    texes[jj.id].video = vs
                    vs.getThumbnail {
                      texes[jj.id].image = XImage.init(cgImage: $0, size: CGSize(width: $0.width, height: $0.height))
                    }
                  texes[jj.id].texture = vs.myTexture
                  uuid = UUID()
                }
                #endif
              }

            }
              return true
            }

            if y[0].canLoadObject(ofClass: NSString.self) {
              y[0].loadObject(ofClass: NSString.self) { (s, e) in
                if let e = e {
                  print(e.localizedDescription)
                  return
                }
                if let s = s as? String, s == "webcam" {
                  let z = WebcamSupport(camera: "FIXME:")
                  z.startVideo()
                  texes[jj.id].video = z // WebcamSupport()
                  texes[jj.id].image = XImage(named: "webcam_still")!
   //               texes[jj.id].texture = z.frameTexture
                  uuid = UUID()

                }
              }
              return true
            }

            if y[0].hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
              y[0].loadItem(forTypeIdentifier: UTType.movie.identifier) {
                (v, err) in
                if let e = err {
                  print(e.localizedDescription)
                  return
                }

                #if os(iOS)
                if let vv = v as? NSURL {
                  let k = AVURLAsset(url: vv as URL)
                  let vs = VideoSupport(asset: k)
                  texes[jj.id].video = vs
                  vs.getThumbnail { g in
                    texes[jj.id].image = XImage.init(cgImage: g) // , size: CGSize(width: $0.width, height: $0.height))
                  }
                  texes[jj.id].texture = vs.myTexture
                  uuid = UUID()
                }
                #endif
              }
              return true
            }

            if y[0].hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            y[0].loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
              (data, error) in
              if let d = data as? Data, let s = String(data: d, encoding: .utf8), s == "webcam" {
                // I guess I should initialize the webcam here?
                // and also grab a thumbnail frame
                let z = WebcamSupport(camera: "FIXME")
                z.startVideo()
                texes[jj.id].video = z // WebcamSupport()
                texes[jj.id].image = XImage(named: "webcam_still")!
 //               texes[jj.id].texture = z.frameTexture
                uuid = UUID()
              }
            }
              return true
            }

            /*
            y[0].loadItem(forTypeIdentifier: UTType.jpeg.identifier, options: nil) {
              (im, err) in
              if let e = err {
                print(e.localizedDescription)
                return
              }
              if let im = im as? XImage {
                print("image?")
              }
            }

            y[0].loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) {
              (urlData, error)  in
              //            defer {
              //              sem.signal()
              //            }
              if let e = error {
                print(e.localizedDescription)
                return
              }

              if let urlData = urlData as? Data {
                let j = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL

                // FIXME: Fix this on StackOverflow
                let uti = UTType.types(tag: j.pathExtension, tagClass: UTTagClass.filenameExtension, conformingTo: UTType.data)
                /*            let uti = UTTypeCreatePreferredIdentifierForTag(
                 kUTTagClassFilenameExtension,
                 j.pathExtension as CFString,
                 nil)
                 let utix = uti?.takeRetainedValue()
                 */

                // FIXME: bring it back for iOS
                #if os(macOS)
                if uti[0].conforms(to: UTType.image) {
                  if let k = XImage.init(contentsOf: j) {
                    texes[jj.id].image = k
                    texes[jj.id].texture = k.getTexture(MTKTextureLoader(device: device))
                    uuid = UUID()
                    res = true
                  }
                } else if uti[0].conforms(to: .movie) {
                  let vs = VideoSupport(j)
                  texes[jj.id].video = vs
                  vs.getThumbnail {
                    texes[jj.id].image = XImage.init(cgImage: $0, size: CGSize(width: $0.width, height: $0.height))
                  }
                  uuid = UUID()
                  res = true
                } else {
                  // fail
                  print("unknown file type dropped")
                }
                #endif
                
              }
              return
            }
            return true // res
             */
            return false
          }).frame(width: 100, height: 100).border(Color.purple, width: 4)
      }
      Text(uuid.uuidString).hidden()
    }
  }
}

/*
struct SourceStrip : View {


  var body: some View {
    return HStack {
      AnyView(
      Image(systemName: "video.circle" )
        ).onDrag {
          #if os(macOS)
        let z = NSItemProvider(object: "webcam" as NSString )
        z.loadObject(ofClass: NSString.self) { (x, e) in print(x, e) }
          #else
          let z = NSItemProvider(object: UIImage(systemName: "video.circle")! )
          #endif
          print("dragged")
        return z
      }
      Spacer()
    }
  }
}
*/

