//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

import SwiftUI
import MetalKit

struct MyDropDelegate : DropDelegate {
  var target : Int
  var shader : RenderManager

  init(_ t : Int, _ s : RenderManager) {
    target = t
    shader = s
  }

  func validateDrop(info: DropInfo) -> Bool {
    print(info)

    return true
  }

  func performDrop(info: DropInfo) -> Bool {

/*    (of: , isTargeted: nil) {
      ips in
      print("ips \(ips.count)")
      print(ips)

      let j = ips[0].loadObject(ofClass: NSMutableString.self) {
        print($0, $1)
      }

      print(j)
      return true
 */

    print(info)
    if let item = info.itemProviders(for: ["public.file-url"]).first {
      item.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) {
        (urlData, error)  in
        print(error)
        if let urlData = urlData as? Data {
          let j = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
          if let k = NSImage.init(contentsOf: j) {
            self.shader.config.inputTexture[self.target] = k.getTexture(MTKTextureLoader(device: device))
          }
        }
      }
    }

    if let item = info.itemProviders(for: ["public.url"]).first {
      item.loadItem(forTypeIdentifier: "public.url", options: nil) {
        (urlData, error) in
        if let urlData = urlData as? Data {
          let j = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
          print(j.absoluteString, j.scheme, j.pathComponents)
        }

      }
    }

  /*  if let item = info.itemProviders(for: ["public.tiff"]).first {
      item.loadFileRepresentation(forTypeIdentifier: "public.tiff") {
        (urlData, error) in
        if let urlData = urlData as? Data {
          let j = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
          print(j.absoluteString, j.scheme, j.pathComponents)
        }

      }
    }
 */

/*
      item.loadDataRepresentation(forTypeIdentifier: kUTTypeFileURL as String) {
        (urlData, error) in
        print(error)
        if let urlData = urlData as? Data {
          let j = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
          print(j)
          print(j.path)

        }
      }

      print("has png ",item.hasRepresentationConforming(toTypeIdentifier: "public.png", fileOptions: []))

      item.loadFileRepresentation(forTypeIdentifier: "public.png") {
        (urlData, error)  in
        print(error)
        if let urlData = urlData as? Data {
          let j = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
          print(j)
          print(j.path)
        }
      }


    }
*/

    return true
    }
}
struct ShaderView: View {
  @ObservedObject var message : Message
  @ObservedObject var shader : RenderManager
  
  var mtv : MetalViewC
  
  
  init(message: Message, shader: RenderManager) {
    self.message = message
    self.shader = shader
    self.mtv = MetalViewC(shader: shader)
  }
  
  var body: some View {
    HSplitView() {
      VStack {
      GeometryReader { g in
        VStack() {
          TextField("Message", text: self.$message.msg).disabled(true)
          Text(self.shader.myName)
          self.mtv.frame(minWidth: 400, idealWidth: 800, maxWidth: 3200, minHeight: 225, idealHeight: 450, maxHeight: 1800, alignment: .top)
            .aspectRatio(16/9.0, contentMode: .fit).layoutPriority(101.0)
            .onAppear(perform: {
              self.shader.isRunning = true
              self.shader.rewind()
              self.shader.play()
//              self.message.msg = "Ready"
            }).onDisappear(perform: {
              self.shader.isRunning = false
              self.shader.stop()
            })
          ControlsView(shader: self.shader, frameTimer: self.shader.frameTimer, metalView: self.mtv.mtkView                                                      ).frame(minWidth: g.size.width)
          PreferencesView(shader: self.shader )
        }
      }.frame(minWidth: 600)
      }.layoutPriority(105);
      VStack() {
        HStack() {
          // Something in here gives me a "Bound preference Key tried to update multiple times per frame
          Image(shader.textureThumbnail[0], scale: 1, label: Text("Texture 1") ).resizable().scaledToFit().frame(width: 100, height: 100)
            .onDrop(of: ["public.url", "public.image", "public.tiff"], delegate: MyDropDelegate(0, shader) )
            .onDrag() {
              let a = URL(string: "mtlx:///0")!
              return NSItemProvider(object: a as NSURL)
            }
          .onTapGesture {
           print("open panel?")
          }
          Image(shader.textureThumbnail[1], scale: 1, label: Text("Texture 2") ).resizable().scaledToFit().frame(width: 100, height: 100)
          .onDrop(of: ["public.url", "public.image", "public.tiff"], delegate: MyDropDelegate(1, shader) )
          Image(shader.textureThumbnail[2], scale: 1, label: Text("Texture 3") ).resizable().scaledToFit().frame(width: 100, height: 100)
          .onDrop(of: ["public.url", "public.image", "public.string"], delegate: MyDropDelegate(2, shader) )
          Image(shader.textureThumbnail[3], scale: 1, label: Text("Texture 4") ).resizable().scaledToFit().frame(width: 100, height: 100)
          .onDrop(of: ["public.url", "public.image", "public.string"], delegate: MyDropDelegate(3, shader) )
        }
        
        HStack() {
          Image(shader.videoThumbnail[0], scale: 1, label: Text("Video 1") ).resizable().scaledToFit().frame(width: 100, height: 100)
          .onDrop(of: ["public.file-url"], delegate: MyDropDelegate(4, shader) )
          Image(shader.videoThumbnail[1], scale: 1, label: Text("Video 2") ).resizable().scaledToFit().frame(width: 100, height: 100)
          .onDrop(of: ["public.file-url", "public.image", "public.string"], delegate: MyDropDelegate(5, shader) )
          Image(shader.videoThumbnail[2], scale: 1, label: Text("Video 3") ).resizable().scaledToFit().frame(width: 100, height: 100)
          .onDrop(of: ["public.file-url", "public.image", "public.string"], delegate: MyDropDelegate(6, shader) )
          /*Image(shader.videoTexture[3]?.toImage() ?? empty, scale: 1, label: Text("Video 4") ).resizable().scaledToFit().frame(width: 100, height: 100)
 */
        }
        
        HStack() {
          EmptyView()
          Color(.green)
        }.frame(minWidth: 100, minHeight: 100)
        
      }
      }
  }
}


struct ShaderView_Previews: PreviewProvider {
  @ObservedObject static var shader = RenderManager("clem")
  @ObservedObject static var msg = Message()
  static var previews: some View {
    ShaderView(message: msg, shader: shader)
  }
}
