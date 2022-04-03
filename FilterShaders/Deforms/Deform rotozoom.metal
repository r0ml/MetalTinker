
#define shaderName deform_rotozoom

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float2 p = worldCoordAspectAdjusted;
  
  float2x2 rot = (1.0 + 0.5*cos(uni.iTime))*rot2d(uni.iTime);

  float3 col = tex.sample( iChannel0, 0.5 + 0.5*rot*p ).xyz;
  return float4( col, 1.0 );
}

