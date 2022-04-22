
#define shaderName colored_circles

#include "Common.h" 

fragmentFn() {
  float t = uni.iTime*2;
  float x=cos(t);
  float y=sin(t);

  float2 s = uni.iResolution.xy;
  float2 b = worldCoordAspectAdjusted * 2 * rot2d(t/5);
  float2 f = (float2(x,b.y)*500/(dot(b,b) - 1) / s.xy * 2 - 1) * float2(s.x/s.y, 1) * float2x2(x, -y, y, x);
  
  return float4(dot(f,f.yx), f, 1);
}
