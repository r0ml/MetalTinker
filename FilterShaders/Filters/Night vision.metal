
#define shaderName night_vision

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float2 p = textureCoord;
  
  float2 u = worldCoordAspectAdjusted;
  float2 n = u * float2(uni.iResolution.x / uni.iResolution.y, 1.0);
  float3 c = tex.sample(iChannel0, p).xyz;
  
  
  // flicker, grain, vignette, fade in
  c += sin(rand(uni.iTime)) * 0.01;
  c += rand((rand(n.x) + n.y) * uni.iTime) * 0.5;
  c *= smoothstep(length(n * n * n * float2(0.075, 0.4)), 1.0, 0.4);
  c *= smoothstep(0.001, 3.5, uni.iTime) * 1.5;
  
  c = luminance(c) * float3(0.2, 1.5 - rand(uni.iTime) * 0.1,0.4);
  
  return float4(c,1.0);
}
