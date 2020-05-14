
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import Accelerate

class DComplex {
  var realp : [Float]
  var imagp : [Float]
  var split : DSPSplitComplex
  
  init(capacity: Int) {
    realp = Array<Float>(repeating: 0, count: capacity)
    imagp = Array<Float>(repeating: 0, count: capacity)
    split = DSPSplitComplex(realp: &realp, imagp: &imagp)
  }
}

class FFT {
  var frameCount : Int
  var inputCount : Int
  var complex : DComplex
  
  var magnitudes : [Float]
  var outputR : [Float]
  var outputI : [Float]
  var window : [Float]
  var tempWindow : [Float]
  var dftSetup : vDSP_DFT_Setup!
  
  init(frameCount fc:Int) {
    frameCount = fc
    let log2n = Int(floor(log2f(Float(fc))))
    let windowSize = Int(1<<log2n)
    inputCount = windowSize / 2
    
    dftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(windowSize), .FORWARD)
    
    window = [Float](repeating: 0, count: windowSize)
    // vDSP_hamm_window(&window, vDSP_Length(windowSize), 0)
    vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_DENORM))
    
    tempWindow = [Float](repeating: 0, count: windowSize)
    magnitudes = [Float](repeating: 0, count: inputCount)
    
    outputR = [Float](repeating: 0, count: Int(inputCount))
    outputI = [Float](repeating: 0, count: Int(inputCount))
    complex = DComplex(capacity: inputCount)
  }
  
  func doFFT(_ bufferData : [Float32] ) -> [Float32] {
    vDSP_vmul(bufferData, 1, window, 1, &tempWindow, 1, vDSP_Length(window.count) )  //  vDSP_Length(bufferData.count) )
    
    let ccc = UnsafePointer(tempWindow).withMemoryRebound(to: DSPComplex.self, capacity: inputCount) {
      UnsafePointer<DSPComplex>($0)
    }
    vDSP_ctoz(ccc, 2, &complex.split, 1, vDSP_Length(bufferData.count / 2))
    
    vDSP_DFT_Execute(dftSetup, complex.split.realp, complex.split.imagp, &outputR, &outputI)
    
    var scale : Float = 1.0 / Float(4 * inputCount)
    vDSP_vsmul(outputR, 1, &scale, &outputR, 1, vDSP_Length(inputCount))
    vDSP_vsmul(outputI, 1, &scale, &outputI, 1, vDSP_Length(inputCount))
    
    //Zero out the nyquist value
    outputI[0] = 0.0
    
    vDSP_vsq(outputR, 1, &outputR, 1, vDSP_Length(outputR.count))
    vDSP_vsq(outputI, 1, &outputI, 1, vDSP_Length(outputI.count))
    vDSP_vadd(outputR, 1, outputI, 1, &magnitudes, 1, vDSP_Length(magnitudes.count))
    
    var one : Float = 1
    vDSP_vdbcon(magnitudes, 1, &one, &magnitudes, 1, vDSP_Length(magnitudes.count), 0)
    
    // min decibels is set to -100
    // max decibels is set to -30
    // calculated range is -128 to 0, so adjust:
    var addvalue : Float = 74
    vDSP_vsadd(magnitudes, 1, &addvalue, &magnitudes, 1, vDSP_Length(magnitudes.count))
    
    scale = Float( 80 /* 128.0 */ / Float(2 * inputCount))  // was 5, was also frameCount // should it be 256 instead of 128?
    vDSP_vsmul(magnitudes, 1, &scale, &magnitudes, 1, vDSP_Length(magnitudes.count))
    
    var vmin : Float = 0;
    var vmax : Float = 1;
    
    var final : [Float] = Array(repeating: 0, count: min(512, magnitudes.count) )
    vDSP_vclip(magnitudes, 1, &vmin, &vmax, &final, 1, vDSP_Length(final.count) )
    return final
  }
  
  deinit {
    vDSP_DFT_DestroySetup(dftSetup)
  }
  
}
