
#define shaderName sunset_and_moonrise

#include "Common.h" 

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted;
  
  float angle = uni.iTime / 2.0;
  float light = sin(angle);
  if (light < 0.0) light = 0.0;
  
  // sky
  float4 fragColor = float4(uv.y * light, uv.y * light, light, 1.0);
  
  // sun
  float2 sun = float2(cos(angle) * 1.9, 1.5 * sin(angle) - 0.7);
  if (length(uv - sun) < 0.1) {
    fragColor = float4(1., 1. * light, 0., 1.0);
  }
  
  // moon
  float delta = 0.05;
  float2 moon = float2(cos(angle + pi) * 1.9, 1.5 * sin(angle + pi) - 0.7);
  float2 moonmask = float2(cos(angle + pi + delta) * 1.9, 1.5 * sin(angle + pi + delta) - 0.7);
  if (length(uv - moon) < 0.1 && length(uv - moonmask) > 0.13) {
    fragColor = float4(1., 1., 1.0, 1.0);
  }
  
  
  // ground
  if (uv.y < -0.2) {
    fragColor = float4(0.1, 0.5 * light + 0.2, 0., 1.0);
  }
  return fragColor;
}
