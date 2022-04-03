
#define shaderName vignette_filter_ii

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float boost = uni.iMouse.x < 0.01 ? 1.5 : uni.iMouse.x * 2.0;
  float reduction = uni.iMouse.y < 0.01 ? 2.0 : uni.iMouse.y * 4.0;
  float2 uv = textureCoord;
  float3 col = tex.sample(iChannel0, uv).rgb;
  float vignette = distance( uni.iResolution.xy * 0.5, thisVertex.where.xy ) / uni.iResolution.x;
  col *= boost - vignette * reduction;
  return float4(col, 1.0);
}
