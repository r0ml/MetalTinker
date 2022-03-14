
#define shaderName DF_Box_Blur

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

constant const int   c_samplesX    = 15;  // must be odd
constant const int   c_samplesY    = 15;  // must be odd
constant const float c_textureSize = 512.0;
constant const float c_pixelSize = (1.0 / c_textureSize);
constant const int   c_halfSamplesX = c_samplesX / 2;
constant const int   c_halfSamplesY = c_samplesY / 2;

fragmentFn(texture2d<float> tex) {
  float2 b = textureCoord;
  int c_distX = uni.mouseButtons
  ? int(float(c_halfSamplesX+1) * uni.iMouse.x )
  : int((sin(uni.iTime*2.0)*0.5 + 0.5) * float(c_halfSamplesX+1));
  
  int c_distY = uni.mouseButtons
  ? int(float(c_halfSamplesY+1) * uni.iMouse.y )
  : int((sin(uni.iTime*2.0)*0.5 + 0.5) * float(c_halfSamplesY+1));
  
  float c_pixelWeight = 1.0 / float((c_distX*2+1)*(c_distY*2+1));
  
  float3 ret = float3(0);
  for (int iy = -c_halfSamplesY; iy <= c_halfSamplesY; ++iy)
  {
    for (int ix = -c_halfSamplesX; ix <= c_halfSamplesX; ++ix)
    {
      if (abs(float(iy)) <= float(c_distY) && abs(float(ix)) <= float(c_distX))
      {
        float2 offset = float2(ix, iy) * c_pixelSize;
        ret += tex.sample(iChannel0, b + offset).rgb * c_pixelWeight;
      }
    }
  }
  return float4(ret, 1);
}
