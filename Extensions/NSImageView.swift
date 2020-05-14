
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import AppKit
import AVFoundation
import MetalKit

// ============================================================================================================
// For drag'n'drop

extension NSImageView {
  override open func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    let allow = shouldAllowDrag(sender)
    return allow ? .copy : NSDragOperation()
  }

  override open func draggingExited(_ sender: NSDraggingInfo?) {
  }

  override open func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let allow = shouldAllowDrag(sender)
    return allow
  }

  fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
    guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
      let path = board[0] as? String
      else { return false }

    // let bb = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType.fileNameType(forPathExtension: "mp4"))
    // print(bb)
    let suffix = URL(fileURLWithPath: path).pathExtension
    for ext in ["mov","mp4"] {
      if ext.lowercased() == suffix {
        return true
      }
    }
    return false
  }

  // FIXME: have drag targets for images and drag targets for videos == they are different
/*  override open func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
    let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes:
      NSImage.imageTypes + [AVFileType.mov,AVFileType.mp4]]

    // isReceivingDrag = false
    let pasteBoard = draggingInfo.draggingPasteboard

    // let point = convert(draggingInfo.draggingLocation, from: nil)

    if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options:filteringOptions) as? [URL], urls.count > 0,
      let c = self.window?.contentViewController as? ShaderViewControllerMac {

      var n = 0
      if self == c.texture0 { n = 0 }
      else if self == c.texture1 { n = 1 }
      else if self == c.texture2 { n = 2 }
      else if self == c.texture3 { n = 3 }

      if let im = NSImage(contentsOf: urls[0]), let s = c.renderManager {
        s.inputTexture[n] = im.getTexture( MTKTextureLoader(device: device) )
      } else if let s = c.renderManager {
        let vs = VideoSupport(urls[0])
        s.config.videoNames[n] = vs
        vs() { z in
          DispatchQueue.main.async { self.image = z }
        }
      }
      return true
    }
    return false

  }
*/
  
  func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
    let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes:
      NSImage.imageTypes  + [AVFileType.mov.rawValue,AVFileType.mp4.rawValue]]

    var canAccept = false

    //2.
    let pasteBoard = draggingInfo.draggingPasteboard

    canAccept = checkExtension(draggingInfo)
    if canAccept { return true }
    //3.
    if pasteBoard.canReadObject(forClasses: [NSURL.self], options: filteringOptions) {
      canAccept = true
    }
    return canAccept

  }


  
}

