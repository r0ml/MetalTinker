
#define shaderName DF_Gaussian_Blur

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

constant const int   c_samplesX    = 15;  // must be odd
constant const int   c_samplesY    = 15;  // must be odd
constant const float c_textureSize = 512.0;
constant const int   c_halfSamplesX = c_samplesX / 2;
constant const int   c_halfSamplesY = c_samplesY / 2;
constant const float c_pixelSize = (1.0 / c_textureSize);

static float Gaussian (float sigma, float x) {
  return exp(-(x*x) / (2.0 * sigma*sigma));
}

fragmentFn(texture2d<float> tex) {
  float c_sigmaX      = uni.mouseButtons ? 5.0 * uni.iMouse.x : (sin(uni.iTime*2.0)*0.5 + 0.5) * 5.0;
  float c_sigmaY      = uni.mouseButtons ? 5.0 * uni.iMouse.y : c_sigmaX;

  float2 b = textureCoord;
  float total = 0.0;
  float3 ret = float3(0);
  
  for (int iy = 0; iy < c_samplesY; ++iy) {
    float fy = Gaussian (c_sigmaY, float(iy) - float(c_halfSamplesY));
    float offsety = float(iy-c_halfSamplesY) * c_pixelSize;
    for (int ix = 0; ix < c_samplesX; ++ix) {
      float fx = Gaussian (c_sigmaX, float(ix) - float(c_halfSamplesX));
      float offsetx = float(ix-c_halfSamplesX) * c_pixelSize;
      total += fx * fy;
      ret += tex.sample(iChannel0, b + float2(offsetx, offsety)).rgb * fx*fy;
    }
  }
  return float4(ret / total, 1);
}
