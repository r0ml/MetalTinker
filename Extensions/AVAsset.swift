
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import AVFoundation

extension AVAsset {
  func getThumbnailImage( _ f : @escaping (CGImage) -> () ) {
    let videoGen = AVAssetImageGenerator.init(asset: self )
    videoGen.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 10)
    videoGen.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 10)
    videoGen.appliesPreferredTrackTransform = true

    let imageGenerator = videoGen
    let z = CMTime(seconds: 10, preferredTimescale: 60)

    do {
      var actualTime : CMTime = CMTime.zero
      let thumb = try imageGenerator.copyCGImage(at: z , actualTime: &actualTime)
      f( thumb )
    } catch let error {
      print("getting thumbnail ", error)
    }
  }
}
