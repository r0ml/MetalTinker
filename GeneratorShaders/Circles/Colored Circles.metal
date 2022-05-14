
#define shaderName colored_circles

#include "Common.h" 

fragmentFunc() {
  float t = scn_frame.time*2;
  float x=cos(t);
  float y=sin(t);

  float2 s = resolution;
  float2 b = worldCoordAdjusted * 2 * rot2d(t/5);
  float2 f = (float2(x,b.y)*500/(dot(b,b) - 1) / s.xy * 2 - 1) * float2(nodeAspect.x, 1) * float2x2(x, -y, y, x);
  
  return float4(dot(f,f.yx), f, 1);
}
