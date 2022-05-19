
#define shaderName deform_rotozoom

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 p = worldCoordAdjusted;
  float t = scn_frame.time;

  float2x2 rot = (1.0 + 0.5*cos(t))*rot2d(t);

  float3 col = tex.sample( iChannel0, 0.5 + 0.5*rot*p ).xyz;
  return float4( col, 1.0 );
}

