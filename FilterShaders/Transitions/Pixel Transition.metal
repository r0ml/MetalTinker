
#define shaderName pixel_transition

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 pixel_count = max(floor(uni.iResolution * (cos(uni.iTime) + 1.0) / 2.0), 1.0);
  float2 pixel_size = uni.iResolution / pixel_count;
  float2 pixel = pixel_size * ( 0.5 + floor(thisVertex.where.xy / pixel_size));
  float2 uv = pixel / uni.iResolution;
  
  uint x = uint((uni.iTime + PI) / TAU) % 2;
  texture2d<float> t = x == 0 ? tex0 : tex1;
  return float4(t.sample(iChannel0, uv).rgb, 1);
}
