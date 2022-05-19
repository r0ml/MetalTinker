
#define shaderName pixel_transition

#include "Common.h" 

fragmentFunc(texture2d<float> tex0, texture2d<float> tex1) {
  float2 pixel_size = scn_frame.inverseResolution;
  float2 pixel_count = max(floor(  (cos(scn_frame.time) + 1.0) / 2.0 / pixel_size), 1.0);

  float2 ps = 1 / (pixel_size * pixel_count);
  float2 pixel = ps * ( 0.5 + floor(thisVertex.where.xy / ps));

  float2 uv = pixel * pixel_size;
  
  uint x = uint((scn_frame.time + PI) / TAU) % 2;
  texture2d<float> t = x == 0 ? tex0 : tex1;
  return float4(t.sample(iChannel0, uv).rgb, 1);
}
