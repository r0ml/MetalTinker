
#define shaderName Cheap_Gaussian_Blur

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

constant const uint ITERATIONS = 128;
constant const float RADIUS = .3;

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float3 sum = tex.sample(iChannel0, uv).xyz;
  
  for(uint i = 0; i < ITERATIONS / 4; i++) {
    sum += tex.sample(iChannel0, uv + float2(float(i) / uni.iResolution.x, 0.) * RADIUS).xyz;
  }
  
  for(uint i = 0; i < ITERATIONS / 4; i++) {
    sum += tex.sample(iChannel0, uv - float2(float(i) / uni.iResolution.x, 0.) * RADIUS).xyz;
  }
  
  for(uint i = 0; i < ITERATIONS / 4; i++) {
    sum += tex.sample(iChannel0, uv + float2(0., float(i) / uni.iResolution.y) * RADIUS).xyz;
  }
  
  for(uint i = 0; i < ITERATIONS / 4; i++) {
    sum += tex.sample(iChannel0, uv - float2(0., float(i) / uni.iResolution.y) * RADIUS).xyz;
  }
  
  return float4(sum / float(ITERATIONS + 1), 1.);
  
}
