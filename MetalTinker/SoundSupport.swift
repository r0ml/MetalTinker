
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Foundation
import AVFoundation
import MetalKit
import os

// I need the NSObject for MicrophoneSupport
class SoundSupport : NSObject {
  var audioEngine : AVAudioEngine? = nil
  var audioBuffer : MTLBuffer?
  var fftBuffer : MTLBuffer?
  
  private var buffer : [Float32] = []
  private var fftResult : [Float32] = []
  
  var musicQ : DispatchQueue = DispatchQueue.init(label: "musicGrabber", attributes: .concurrent)
  var counter = 0
  private var url : URL!
  
//  var frameCount: Int = -1
  var fft : FFT!
  
  init(_ u : URL? ) {
    audioBuffer = device.makeBuffer(length: 4410 * 4, options: [.storageModeShared ])
    audioBuffer?.label = "audio samples"
    
    fftBuffer = device.makeBuffer(length: 512 * 4, options: [.storageModeShared] )
    fftBuffer?.label = "fft samples"
    
    super.init()
    url = u
  }
  
  func startStreaming() {
    audioEngine = AVAudioEngine()
    let am = AVAudioMixerNode()
    let ap = AVAudioPlayerNode()
    let f = try? AVAudioFile(forReading: url)
    audioEngine?.attach(ap)
    audioEngine?.attach(am)
    
    audioEngine?.connect(am, to: audioEngine!.outputNode, format: nil)
    audioEngine?.connect(ap, to: am, format: nil)
    ap.scheduleFile(f!, at: nil, completionHandler: nil)
    
    self.commonStreaming(am)
    
    // this has to come after the engine start.
    ap.play(at: nil)
  }
  

  func commonStreaming( _ inputNode : AVAudioNode) {
    let bus = 0
    let z : AVAudioFormat = inputNode.outputFormat(forBus: bus)
    
    let bs = Int(z.sampleRate) //  / 10.0) // sampling is at 1 tenth of a second?   Always?
    // buffer size for a second worth of audio?
    
//    frameCount = Int(bs / 10 )
    
    fft = FFT(frameCount: Int(bs / 10))
    
//    transferBuffer = [Float](repeating: 0, count: windowSize)
    
    // the problem here is that the sampleRate for the inputFormat on bus is 44100
    // the sampleRate for the outputFormat on bus is 48000
    inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fft.frameCount), format: inputNode.inputFormat(forBus: bus), block: self.captured)
    
    audioEngine!.prepare()
    do {
      try audioEngine!.start()
    } catch let e {
      os_log("%s", type:.debug, "audioEngine start: \(e.localizedDescription)")
    }
    
  }
  
  func stopStreaming() {
//    os_log("%s", type:.debug, "audio engine stop")
    audioEngine?.pause()
    audioEngine?.stop() // should it be audioEngine.pause() ?
  }
  
  func captured(thisBuf: AVAudioPCMBuffer, timex: AVAudioTime) {
    counter += 1

  //  print(timex.debugDescription)
  //  print(timex.hostTime, timex.sampleRate, timex.sampleTime)
    
    
    // let tsr = timex.sampleRate / 60  // this should be number of samples I want per 1/60 second frame.
   guard let fcda = thisBuf.floatChannelData else {
      os_log("%s", type:.error, "didn't have floatChannelData")
      return
    }
    
    musicQ.sync(flags: .barrier) {
      
      let fmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!

      let converter = AVAudioConverter(from: thisBuf.format, to: fmt)
      let convertedBuffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(fmt.sampleRate) * thisBuf.frameLength / AVAudioFrameCount(thisBuf.format.sampleRate))!

      let acib : AVAudioConverterInputBlock = { packetCount, outStatus in
        outStatus.pointee = .haveData
        return thisBuf
      }
      
        var error : NSError? = nil
        let status = converter?.convert(to: convertedBuffer, error: &error, withInputFrom: acib)

      assert(status != .error)
      
      // let buf = thisBuf
      let buf = convertedBuffer
           // This way is to grab an audio buffer and use it for 6 frames
           // Another option is to memcpy the bytes from fcda into buffer

      self.buffer = Array(UnsafeBufferPointer<Float32>(start: buf.floatChannelData![0], count: Int(buf.frameLength)))
      // because of the limit for textures, the maximum length is 16384
      // should the audio buffer and fft result be Buffers instead of Textures?
          self.fftResult = fft.doFFT(self.buffer)
    }
  }
  
    
  func readBuffer( _ timeX : TimeInterval ) -> (MTLBuffer?, MTLBuffer?) {
    var w : [Float32] = []
    var ww : [Float32] = []
    
    musicQ.sync() {
      w = self.buffer
      if fftResult.count > 0 { ww = self.fftResult }
    }

    if w.count == 0 { return (nil,nil) }
    if let a = audioBuffer {
      let len = min(a.length, w.count * 4)
      a.contents().copyMemory(from: w, byteCount: len)
    //  a.didModifyRange(0..<len)
    }
    
//    let td = MTLTextureDescriptor()
//    td.textureType = .type1D
//    // td.height = 1
//    td.width = w.count
//    td.pixelFormat =  .r32Float
    
//    let t = device.makeTexture(descriptor: td)
//    t?.label = "audio samples"
//    let r = MTLRegionMake1D(0, td.width)
//
//    w.withUnsafeBytes { t!.replace(region: r, mipmapLevel: 0, withBytes: $0.baseAddress!, bytesPerRow: w.count * 4) }
    
//    let td2 = MTLTextureDescriptor()
//    td2.textureType = .type1D
//    td2.width = ww.count
//    td2.pixelFormat = .r32Float
//    let t2 = device.makeTexture(descriptor: td2)
//    t2?.label = "frequency samples"
//
    // let r2 = MTLRegion.init(origin: MTLOrigin.init(x: 0, y: 0, z: 0), size: MTLSize.init(width: td2.width, height: 1, depth: 1))
//    ww.withUnsafeBytes { t2?.replace(region: r2, mipmapLevel: 0, withBytes: $0.baseAddress!, bytesPerRow: ww.count * 4) }
    if let f = fftBuffer {
      let len = min(f.length, ww.count * 4)
      f.contents().copyMemory(from: ww, byteCount: len)
   //   f.didModifyRange(0..<len)
    }
    
    return (audioBuffer, fftBuffer)
  }
}
