
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#if os(macOS)

import AppKit

/*
 extension NSImageView {
 func setImage(fromData im : Data?) {
 guard let im = im else { return }
 let z = imageFromData(im)
 if self.wantsLayer == false {
 self.layer = CALayer()
 self.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
 self.wantsLayer = true
 }

 /** fade the thumbnail image in */
 let transition = CATransition() //create transition
 transition.duration = 1 //set duration time in seconds
 transition.type = .fade //animation type
 transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
 self.layer?.add(transition, forKey: kCATransition) //add animation to your imageView's layer

 self.layer?.contents = z

 }
 }
 */

// ====================================================================================================================

extension NSView {
  public func firstOne<T>() -> T? {
    if let z = self.subviews.first(where: { $0 is T }) {
      return z as? T
    }
    for v in self.subviews {
      if let z : T? = v.firstOne() { return z}
    }
    return nil
  }
}

#endif
