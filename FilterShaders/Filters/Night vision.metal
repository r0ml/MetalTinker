
#define shaderName night_vision

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 p = textureCoord;
  
  float2 u = worldCoordAdjusted;
  float2 n = u * nodeAspect;
  float3 c = tex.sample(iChannel0, p).xyz;
  float t = scn_frame.time;
  
  // flicker, grain, vignette, fade in
  c += sin(rand(t)) * 0.01;
  c += rand((rand(n.x) + n.y) * t) * 0.5;
  c *= smoothstep(length(n * n * n * float2(0.075, 0.4)), 1.0, 0.4);
  c *= smoothstep(0.001, 3.5, t) * 1.5;
  
  c = luminance(c) * float3(0.2, 1.5 - rand(t) * 0.1,0.4);
  
  return float4(c,1.0);
}
