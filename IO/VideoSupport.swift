
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#if os(macOS)
import AppKit
#endif

import MetalKit
import AVFoundation
import os
import CoreVideo

import MediaToolbox

import Accelerate

class VideoSupport : VideoStream {
  private var video : AVAsset
  private var url : URL

  // FIXME: make private again?
  /* private */ var myTexture : MTLTexture?
  private var reader : AVAssetReader?
  private var player : AVQueuePlayer
  private var textureQ = DispatchQueue(label: "videoTextureQ")
  private var looper : AVPlayerLooper
  private var observation: NSKeyValueObservation?

  init( url u : URL ) {
    url = u
    video = AVAsset(url: u)
    player = AVQueuePlayer()
    let pi = AVPlayerItem.init(asset: video )
    looper = AVPlayerLooper(player: player, templateItem: pi)
    doInit(asset: video)
  }

  init( asset v : AVURLAsset ) {
    url = v.url
    video = v
    player = AVQueuePlayer()
    let pi = AVPlayerItem.init(asset: video )
    looper = AVPlayerLooper(player: player, templateItem: pi)
    doInit(asset: video)
  }

  private func doInit(asset video : AVAsset) {
    observation = looper.observe(\AVPlayerLooper.status, options: .new) { object, change in
      let status = self.looper.status
      // Switch over status value
      switch status {
      case .ready:
        // Player item is ready to play.
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        self.looper.loopingPlayerItems.forEach { pis in
          let playerItemVideoOutput: AVPlayerItemVideoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)

          pis.add(playerItemVideoOutput)
        }
      case .cancelled:
        // Player item failed. See error.
        break
      case .unknown:
        break
      // Player item is not yet ready.
      default:
        break
      }
    }
  }

  func pause() {
    player.pause()
  }
  
  func start() {
    player.play()
    return
  }
  
  var loop : Bool = false

  func startVideo() {
  }
  
  func stopVideo() {
    player.pause()
  }

  func getPixels(_ currentTime : CMTime) -> MTLTexture? {
    let pivo = player.currentItem!.outputs[0] as! AVPlayerItemVideoOutput
    // let currentTime = pivo.itemTime(forHostTime: nextVSync)
    
    if pivo.hasNewPixelBuffer(forItemTime: currentTime),
       let pixelBuffer = pivo.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)  {
      
      var vib = vImage_Buffer()
      var format = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        colorSpace: nil,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
        version: 0,
        decode: nil,
        renderingIntent: .perceptual)
      
      let _ /*error*/ = vImageBuffer_InitWithCVPixelBuffer(&vib,
                                                           &format,
                                                           pixelBuffer,
                                                           vImageCVImageFormat_CreateWithCVPixelBuffer(pixelBuffer).takeUnretainedValue(),
                                                           nil,
                                                           vImage_Flags(kvImageNoFlags))
      
      // vImageVerticalReflect_ARGB8888(&vib, &vib, vImage_Flags(kvImageDoNotTile) )


      // FIXME: should I do the mipmaps explicitly ?
      
      let mtd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:
        .bgra8Unorm, width:CVPixelBufferGetWidth(pixelBuffer),
                     height: CVPixelBufferGetHeight(pixelBuffer), mipmapped: true)

      let tx = device.makeTexture(descriptor: mtd)
      tx?.label = "video frame"
      let region = MTLRegionMake2D(0, 0, mtd.width, mtd.height)
      
      CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
      if let dd = CVPixelBufferGetBaseAddress(pixelBuffer) {
        tx?.replace(region: region, mipmapLevel: 0, withBytes: dd, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly);
      }
      CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
      return tx
    } else {
      return myTexture
    }
  }
  
  func readBuffer(_ nVSync : TimeInterval) -> MTLTexture? {
    var nextVSync = nVSync

    if player.timeControlStatus == .paused {
      player.play()
      nextVSync += 10
      return nil
    }

    if player.timeControlStatus != .playing {
      player.play()
      return nil
    }

    guard looper.loopingPlayerItems.count > 0 else {
      return nil
    }

    let pivo = player.currentItem!.outputs[0] as! AVPlayerItemVideoOutput
    let currentTime = pivo.itemTime(forHostTime: nextVSync)
    let tx = getPixels(currentTime)
    self.myTexture = tx
    return tx
  }

  // FIXME: I could cache the thumbnail for future reference
  func getThumbnail(_ f : @escaping (CGImage) -> ()) {
    video.getThumbnailImage(f)
  }

  var observer : NSObject?

}
