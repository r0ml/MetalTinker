
#define shaderName vignette_filter

#include "Common.h" 

fragmentFunc(texture2d<float> tex, constant float2& mouse) {
  constexpr sampler iChannel0(coord::normalized, address::repeat, filter::linear);
  float2 uv = textureCoord;
  float3 col = tex.sample(iChannel0, uv ).rgb;
  float dist = distance(uv, float2(0.5)),
  falloff = mouse.y < 0.01 ? 0.1 : mouse.y,
  amount = mouse.x < 0.01 ? 1.0 : mouse.x ;
  col *= smoothstep(0.8, falloff * 0.8, dist * (amount + falloff));
  return float4(col, 1.0);
}
