// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import AVFoundation
import CoreMedia
import MetalKit
import os
import SwiftUI

class WebcamSupport : NSObject, VideoStream {
  private var frameTexture : MTLTexture? = nil
  private var region : MTLRegion = MTLRegion()

  private var permissionGranted = false
  private let captureSession = AVCaptureSession()
  private let context = CIContext()
  private let name : String

  init(camera n : String) {
    name = n
    super.init()
    checkPermission()
    self.configureSession()
  }
  
  func startCapture() {
    startVideo()
  }
  
  func stopCapture() {
    stopVideo()
  }
  
  func prepare() -> MTLTexture? {
    return /* frameQ.sync(flags: .barrier) { */ self.frameTexture
  }

  func readBuffer(_ nVSync : TimeInterval) -> MTLTexture? {
    return self.frameTexture
  }


  func startVideo() {
    captureSession.startRunning()
  }

  func stopVideo() {
    captureSession.stopRunning()
  }


}

extension WebcamSupport :  AVCaptureVideoDataOutputSampleBufferDelegate {
  
  private func checkPermission() {
    switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
    case .authorized:
      permissionGranted = true
    case .notDetermined:
      requestPermission()
    default:
      permissionGranted = false
    }
  }
  private func requestPermission() {
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
      self.permissionGranted = granted
    }
  }
  
  private func configureSession() {
    if permissionGranted,
      let captureDevice = selectCaptureDevice(),
      let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) {
      
      captureSession.sessionPreset = .medium
      if captureSession.canAddInput(captureDeviceInput) { captureSession.addInput(captureDeviceInput) }
      
      let videoOutput = AVCaptureVideoDataOutput()
      // videoOutput.alwaysDiscardsLateVideoFrames = true
      videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
      videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]

      let z = CMVideoFormatDescriptionGetDimensions(captureDevice.activeFormat.formatDescription)
      print(z)

      let mtd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:
        thePixelFormat, width: Int(z.width), height: Int(z.height), mipmapped: false)
      let tx = device.makeTexture(descriptor: mtd)
      tx?.label = "webcam frame"
      tx?.setPurgeableState(.keepCurrent)
      self.frameTexture = tx
      region = MTLRegionMake2D(0, 0, mtd.width, mtd.height)

      if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
      captureSession.commitConfiguration()
    }
  }
  
  private func selectCaptureDevice() -> AVCaptureDevice? {
    let j = CameraPicker.getDevice(name) // AVCaptureDevice.default(for: .video)// .filter { d in
//      d.localizedName.starts(with: "LG")
//    }
    return j
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      if let tx = self.frameTexture {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        if let dd = CVPixelBufferGetBaseAddress(pixelBuffer) {
          tx.replace(region: region, mipmapLevel: 0, withBytes: dd, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer))
          CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
      }
    }
  }
}

/// The drop down list for macOS to select the camera in the event that there are multiple cameras available.
public struct CameraPicker : View {
  @Binding var cameraName : String

  public init(cameraName: Binding<String>) {
    _cameraName = cameraName
  }

  public var body : some View {
#if os(macOS) || targetEnvironment(macCatalyst)
    Picker(selection: $cameraName, label: Text("Choose a camera") ) {
      ForEach( Self.cameraList, id: \.self) { cn in
        Text(cn)
      }
    }
#else
    EmptyView()
#endif
  }

#if os(iOS)
  static public var _cameraList : [AVCaptureDevice] { get {
    let aa = ProcessInfo.processInfo
    let bb = aa.isiOSAppOnMac || aa.isMacCatalystApp
    let availableDeviceTypes : [AVCaptureDevice.DeviceType] = [.builtInTrueDepthCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .builtInTripleCamera]
    let foundVideoDevices = AVCaptureDevice.DiscoverySession.init(deviceTypes: availableDeviceTypes, mediaType: .video , position: bb ? .unspecified :  /* frontCamera ? .front : */ .back).devices
    return foundVideoDevices
  }}
#elseif os(macOS)
  static public var _cameraList : [AVCaptureDevice] { get {
    return AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: AVCaptureDevice.Position.unspecified).devices
  } }
#endif

  static var cameraList : [String] { get {
    return Self._cameraList.map(\.localizedName)
  }}

  static func getDevice(_ s : String) -> AVCaptureDevice? {
    let list = CameraPicker._cameraList
    if let videoCaptureDevice = list.first(where : { $0.localizedName == s })  {
      return videoCaptureDevice
    } else {
      if let a = list.first {
        return a
      }
    }
    return nil
  }

}
