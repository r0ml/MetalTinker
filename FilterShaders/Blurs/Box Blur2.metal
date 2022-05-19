
#define shaderName box_blur2

#include "Common.h"

fragmentFunc(texture2d<float> tex, device float2& mouse) {
  const int   c_samplesX    = 15;  // must be odd
  const int   c_samplesY    = 15;  // must be odd
  const float c_textureSize = 512.0;
  const float c_pixelSize = (1.0 / c_textureSize);
  const int   c_halfSamplesX = c_samplesX / 2;
  const int   c_halfSamplesY = c_samplesY / 2;

  float2 uv = textureCoord;

  int c_distX = int(float(c_halfSamplesX+1) * mouse.x );
//    : int((sin(uni.iTime*2.0)*0.5 + 0.5) * float(c_halfSamplesX+1));

  int c_distY = int(float(c_halfSamplesY+1) * mouse.y );
//    : int((sin(uni.iTime*2.0)*0.5 + 0.5) * float(c_halfSamplesY+1));

  float c_pixelWeight = 1.0 / float((c_distX*2+1)*(c_distY*2+1));

  float3 ret = float3(0);
  for (int iy = -c_halfSamplesY; iy <= c_halfSamplesY; ++iy)
  {
    for (int ix = -c_halfSamplesX; ix <= c_halfSamplesX; ++ix)
    {
      if (abs(float(iy)) <= float(c_distY) && abs(float(ix)) <= float(c_distX))
      {
        float2 offset = float2(ix, iy) * c_pixelSize;
        ret += tex.sample(iChannel0, uv + offset).rgb * c_pixelWeight;
      }
    }
  }
  return float4(ret, 1);

}
