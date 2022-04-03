
#define shaderName ellipse_geometry

#include "Common.h" 

fragmentFn() {
  float2 p1=float2(0.,0.);
  float2 uv = worldCoordAspectAdjusted;
  
  float2 p2 = (2*uni.iMouse.xy - 1) * aspectRatio;

  float col = distance(uv,p1)+distance(uv,p2);
  return float4( float3(smoothstep(1, 1,col)), 1);
}
