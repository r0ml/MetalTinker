
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import UniformTypeIdentifiers
import MetalKit

struct ImageStrip : View {
  @Binding var texes : [TextureParameter]
  @State var uuid = UUID()

  var body : some View {
    HStack {
      ForEach(texes) { (jj) in

        // FIXME: i windws up out of range -- must be from resetting texes
        Image.init(xImage: texes[jj.id].image).resizable().scaledToFit()
          .onDrop(of: [UTType.fileURL, UTType.plainText, UTType.image], isTargeted: nil, perform: { (y) in

            var res = false
            //          var sem = DispatchSemaphore(value: 0)

            //          DispatchQueue.global().async {
            /*          y[0].loadItem(forTypeIdentifier: UTType.image.identifier, options: nil ) {
             (im, error) in
             print(im)
             print(error)
             }

             */
            y[0].loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
              (data, error) in
              if let d = data {
                // I guess I should initialize the webcam here?
                // and also grab a thumbnail frame
                let z = WebcamSupport()
                z.startRunning()
                texes[jj.id].video = z // WebcamSupport()
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
          }).frame(width: 100, height: 100).border(Color.purple, width: 4)
      }
      Text(uuid.uuidString).hidden()
    }
  }
}


struct SourceStrip : View {

  var body: some View {
    let z = NSItemProvider(item: "webcam".data(using: .utf8)as NSSecureCoding?, typeIdentifier: UTType.plainText.identifier)

    return HStack {
      Image(systemName: "video.circle" ).onDrag {
        return z
      }
    }
  }
}

