
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import AppKit
import AVFoundation
import MetalKit
import os

class MicrophoneSupport : SoundSupport, AVCaptureAudioDataOutputSampleBufferDelegate {
  private var permissionGranted = false

  init() {
    super.init( nil )
    checkPermission()
  }
  
  override func startStreaming() {
    let _ = selectCaptureDevice()
    
    let j = self.audioDeviceList()
    
    audioEngine  = AVAudioEngine()
    let inputNode = audioEngine!.inputNode
    
    
    let inputUnit: AudioUnit = inputNode.audioUnit!
    var inputDeviceID: AudioDeviceID = j[0]
    AudioUnitSetProperty(inputUnit, kAudioOutputUnitProperty_CurrentDevice,
                         kAudioUnitScope_Global, 0, &inputDeviceID, UInt32(MemoryLayout<AudioDeviceID>.size))
    
    
    self.commonStreaming(inputNode)
  }

  func audioDeviceList() -> [AudioDeviceID] {
    var mDevices : [AudioDeviceID] = []
    
    var propsize : UInt32 = 0
    
    var theAddress : AudioObjectPropertyAddress = AudioObjectPropertyAddress.init(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
    
    // = [ AudioObjectID(kAudioHardwarePropertyDevices),
    // kAudioObjectPropertyScopeGlobal,
    // kAudioObjectPropertyElementMaster ]
    
    let _ = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &theAddress, 0, nil, &propsize)
    // print("AudioObjectGetPropertyDataSize", err)
    let nDevices : Int = Int(propsize) / MemoryLayout<AudioDeviceID>.stride
    
    var devids : [AudioDeviceID] = Array(repeating: 0, count: nDevices)
    
    let _ = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &theAddress, 0, nil, &propsize, &devids)
    // print("AudioObjectGetPropertyData", err2)
    
    
    var propertyAddress = AudioObjectPropertyAddress.init(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: kAudioObjectPropertyScopeInput, mElement: kAudioObjectPropertyElementMaster)
    
    for j in devids {
      var datsiz : UInt32 = 0
      let a1 = AudioObjectGetPropertyDataSize(j, &propertyAddress, 0, nil, &datsiz)
      print("a1 \(a1)")
      let bb = AudioBufferList.allocate(maximumBuffers: Int(datsiz))
      let _ = AudioObjectGetPropertyData(j, &propertyAddress, 0, nil, &datsiz, bb.unsafeMutablePointer)
      var channelCount = 0
      for i in 0..<Int(bb.unsafeMutablePointer.pointee.mNumberBuffers) {
        channelCount = channelCount + Int(bb[i].mNumberChannels)
      }
      free(bb.unsafeMutablePointer)
      if channelCount > 0 {
        let z = audioDeviceGetName(j) ?? "no name"
        print("audio input device \(j) = \(z)")
        mDevices.append(j)
        
      }
      // print(audioDeviceGetName(j) as Any)
      // print("channels", audioDeviceCountChannels(j))
    }
    return mDevices
  }
  
  
  
  func audioDeviceCountChannels(_ mID : AudioDeviceID) -> Int {
    let theScope : AudioObjectPropertyScope = /* mIsInput ? */ kAudioDevicePropertyScopeInput // : kAudioDevicePropertyScopeOutput;
    
    var theAddress = AudioObjectPropertyAddress.init(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: theScope, mElement: 0)
    
    var propSize : UInt32 = 0
    
    var result = 0
    
    let err = AudioObjectGetPropertyDataSize(mID, &theAddress, 0, nil, &propSize);
    if (err != 0) { return 0 }
    
    var buflist : [AudioBufferList] = Array(repeating: AudioBufferList(), count: Int(propSize) / MemoryLayout<AudioBufferList>.size)
    let err2 = AudioObjectGetPropertyData(mID, &theAddress, 0, nil, &propSize, &buflist)
    if (err2 == 0) {
      for buf in buflist {
        result += Int(buf.mBuffers.mNumberChannels)
      }
    }
    return result
  }
  
  func audioDeviceGetName(_ mID : AudioDeviceID) -> String? {
    let theScope : AudioObjectPropertyScope = /* mIsInput ?  */ kAudioDevicePropertyScopeInput // : kAudioDevicePropertyScopeOutput;
    var theAddress = AudioObjectPropertyAddress.init(mSelector: kAudioDevicePropertyDeviceName, mScope: theScope, mElement: 0)
    var maxlen : UInt32 = 1024
    var buf : Data = Data(count: Int(maxlen) )
    let err = buf.withUnsafeMutableBytes { AudioObjectGetPropertyData(mID, &theAddress, 0, nil,  &maxlen, $0.baseAddress!) }
    os_log("%s", type: .debug, "AudioObjectGetPropertyData \(err)")
    return String.init(data:   buf.subdata(in: 0..<Int(maxlen-1))  , encoding: .utf8)
  }
  
  func audioDeviceSetBufferSize(_ mID : AudioDeviceID, _ z : Int) {
    var size = z
    var propsize : UInt32 = UInt32( MemoryLayout<UInt32>.size )
    let theScope : AudioObjectPropertyScope = /* mIsInput ?  */ kAudioDevicePropertyScopeInput // : kAudioDevicePropertyScopeOutput;
    var theAddress = AudioObjectPropertyAddress.init(mSelector: kAudioDevicePropertyBufferSize, mScope: theScope, mElement: 0)
    let err = AudioObjectSetPropertyData(mID, &theAddress, 0, nil, propsize, &size)
    os_log("%s", type: .debug, "AudioObjectSetPropertyData \(err)" )
    var mBufferSizeFrames : UInt32 = 0
    let err2 = AudioObjectGetPropertyData(mID, &theAddress, 0, nil, &propsize, &mBufferSizeFrames)
    os_log("%s", type: .debug, "AudioObjectGetPropertyData \(err2)")
    if (size != mBufferSizeFrames) {
      os_log("%s", type:.error, "size set is not equal to size got (\(size) <=> \(mBufferSizeFrames))")
    }
  }
// }


// If I do this right, this is the code that is not needed because I'm using AVAudioEngine instead of AVCaptureSession
// class Microphone: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {


  private func checkPermission() {
    switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
    case .authorized:
      permissionGranted = true
    case .notDetermined:
      requestPermission()
    case .denied:
      os_log("%s", type: .error, "**** can't use the microphone!!!");
    case .restricted:
      os_log("%s", type: .error, "*** restricted microphone use!!!");
    default:
      permissionGranted = false
    }
  }
  
  private func requestPermission() {
    // sessionQueue.suspend()
    AVCaptureDevice.requestAccess(for: AVMediaType.audio) { granted in
      self.permissionGranted = granted
      // self.sessionQueue.resume()
    }
  }
  
  private func selectCaptureDevice() -> AVCaptureDevice? {
    let j = AVCaptureDevice.default(for: AVMediaType.audio)
    return j
  }
}
