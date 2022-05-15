
#define shaderName simple_chromatic_abberation

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 uv = textureCoord;
  
  float2 d = abs((uv - 0.5) * 2.0);
  d = pow(d, float2(2.0, 2.0));
  
  float4 r = tex.sample(iChannel0, uv - d * 0.015);
  float4 g = tex.sample(iChannel0, uv);
  float4 b = tex.sample(iChannel0, uv);
  
  return float4(r.r, g.g, b.b, 1.0);
}
