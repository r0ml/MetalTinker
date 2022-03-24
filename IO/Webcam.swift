// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import AVFoundation
import CoreMedia
import MetalKit
import os

class WebcamSupport : NSObject, VideoStream {
  var frameTexture : MTLTexture? = nil
  private var region : MTLRegion = MTLRegion()

  private var permissionGranted = false
//  private let sessionQueue = DispatchQueue(label: "session queue")
  private let captureSession = AVCaptureSession()
  private let context = CIContext()
  
  override init() {
    super.init()
    checkPermission()
//    sessionQueue.async {
      self.configureSession()
      // self.captureSession.startRunning()
//    }
  }
  
  func startCapture() {
    startRunning()
  }
  
  func stopCapture() {
    stopRunning()
  }
  
  func prepare() -> MTLTexture? {
    return /* frameQ.sync(flags: .barrier) { */ self.frameTexture
  }

  func readBuffer(_ nVSync : TimeInterval) -> MTLTexture? {
    return self.frameTexture
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
  
  func startRunning() {
    captureSession.startRunning()
  }
  
  func stopRunning() {
    captureSession.stopRunning()
  }
  
  private func requestPermission() {
//    sessionQueue.suspend()
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
      self.permissionGranted = granted
//      self.sessionQueue.resume()
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
    let j = AVCaptureDevice.default(for: .video)// .filter { d in
//      d.localizedName.starts(with: "LG")
//    }
    return j
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
/*      if (frameQ.sync(flags: .barrier) { self.frameTexture == nil } ) {
        let mtd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:
          thePixelFormat, width:  CVPixelBufferGetWidth(pixelBuffer),
                       height: CVPixelBufferGetHeight(pixelBuffer), mipmapped: false)
        let tx = device.makeTexture(descriptor: mtd)
        tx?.label = "webcam frame"
        tx?.setPurgeableState(.volatile)
        frameQ.async { self.frameTexture = tx }
        region = MTLRegionMake2D(0, 0, mtd.width, mtd.height)
      } */
      if let tx = self.frameTexture /*(frameQ.sync(flags: .barrier) { self.frameTexture } */  {
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
