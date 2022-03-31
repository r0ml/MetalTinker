
#define shaderName first_circle

#include "Common.h" 

struct InputBuffer {};
initialize() {}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted;
  
  float l = length(uv);
  float thi = atan2(uv.y,uv.x);
  
  float r = 0.5 + 0.05 * sin(20.0 *thi)*pow(sin(uni.iTime * 5.0),3.0);
  l = step(l,r);
  float3 col = float3(0.0,0.5,0.8);
  return float4(col*l,1.0);
}
