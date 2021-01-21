
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h> // includes CIKernelMetalLib.h

extern "C" { namespace coreimage {
  float4 myColor(sample_t s) {
    return s.grba;
  }
}}
