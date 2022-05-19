
#define shaderName vignette_filter_ii

#include "Common.h" 

fragmentFunc(texture2d<float> tex, constant float2& mouse) {
  float boost = mouse.x < 0.01 ? 1.5 : mouse.x * 2.0;
  float reduction = mouse.y < 0.01 ? 2.0 : mouse.y * 4.0;
  float2 uv = textureCoord;
  float3 col = tex.sample(iChannel0, uv).rgb;
  float vignette = distance( 0.5, textureCoord);
  col *= boost - vignette * reduction;
  return float4(col, 1.0);
}
