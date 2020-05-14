
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import AppKit
import MetalKit
import os

extension NSImage {
  class func swatchWithColor(color: NSColor, size: NSSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    color.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
    image.unlockFocus()
    return image
  }
  
  func getTexture(_ t : MTKTextureLoader, flipped: Bool = false, mipmaps : Bool = true) -> MTLTexture? {
    
    // This business fixed the problem with having a gray-scale png texture
    
    let sourceImageRep = self.tiffRepresentation!
    let targetColorSpace = NSColorSpace.genericRGB
    let targetImageRep = NSBitmapImageRep(data: sourceImageRep)?.converting(to: targetColorSpace, renderingIntent:NSColorRenderingIntent.perceptual)!
    
    do {
      return try t.newTexture(data: targetImageRep!.tiffRepresentation!,
                              options: [
                                .origin :  flipped ? MTKTextureLoader.Origin.flippedVertically : MTKTextureLoader.Origin.bottomLeft,
                                .SRGB: NSNumber(value: false),
                                .generateMipmaps : NSNumber(value: mipmaps)])
    } catch let e {
      os_log("getting texture: %s", type: .error, e.localizedDescription)
    }
    return nil
  }
  
  func getCube(_ t : MTKTextureLoader) -> MTLTexture? {
    
    // This business fixed the problem with having a gray-scale png texture
    
    let sourceImageRep = self.tiffRepresentation!
    let targetColorSpace = NSColorSpace.genericRGB
    let targetImageRep = NSBitmapImageRep(data: sourceImageRep)?.converting(to: targetColorSpace, renderingIntent:NSColorRenderingIntent.perceptual)!
    
    do {
      return try t.newTexture(data: targetImageRep!.tiffRepresentation!,
                              options: [
                                // FIXME: This was already commented.  Should I flip vertically here (are 3D images strange?
                                // .origin : MTKTextureLoader.Origin.flippedVertically,
                                .SRGB: NSNumber(value: false),
                                .textureUsage : NSNumber(value: 0),
                                .cubeLayout : MTKTextureLoader.CubeLayout.vertical,
                                .generateMipmaps : NSNumber(value: true)
                                // .allocateMipmaps : true
      ])
    } catch let e {
      os_log("getting texture: %s", type: .error, e.localizedDescription)
    }
    return nil
  }
  
  func drawTextInCurrentContext( _ text : String, attr:[NSAttributedString.Key:Any], paddingX: CGFloat, paddingY: CGFloat) {
    let textSize = text.size(withAttributes: attr)
    let textRect = CGRect(x: self.size.width - textSize.width - paddingX, y: self.size.height - textSize.height - paddingY, width: textSize.width, height: textSize.height)
    text.draw(in: textRect, withAttributes:attr)
  }
  
  public func resizedImage(withMaximumSize size : CGSize) -> NSImage? {
    // let imgRef = self.CGImageWithCorrectOrientation()!
    let original_width  = CGFloat(self.size.width)
    let original_height = CGFloat(self.size.height)
    let width_ratio = size.width / original_width
    let height_ratio = size.height / original_height
    let scale_ratio = width_ratio < height_ratio ? width_ratio : height_ratio
    return self.drawImageInBounds( CGRect(x: 0, y: 0, width: round(original_width * scale_ratio), height: round(original_height * scale_ratio)))
  }
  
  public func drawImageInBounds( _ bounds : CGRect) -> NSImage? {
    return self
  }
  
  func writePNG(toURL url: URL) {
    guard let data = tiffRepresentation,
      let rep = NSBitmapImageRep(data: data),
      let imgData = rep.representation(using: .png, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {
        
        Swift.print("\(self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(url)")
        return
    }
    
    do {
      try imgData.write(to: url)
    } catch let error {
      Swift.print("\(self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
    }
  }
}
