
#define shaderName vignette_filter

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  constexpr sampler iChannel0(coord::normalized, address::repeat, filter::linear);
  float2 uv = textureCoord;
  float3 col = tex.sample(iChannel0, uv ).rgb;
  float dist = distance(uv, float2(0.5)),
  falloff = uni.iMouse.y < 0.01 ? 0.1 : uni.iMouse.y,
  amount = uni.iMouse.x < 0.01 ? 1.0 : uni.iMouse.x ;
  col *= smoothstep(0.8, falloff * 0.8, dist * (amount + falloff));
  return float4(col, 1.0);
}
