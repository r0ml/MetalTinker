
#define shaderName fading_effect_practice

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

 


float dfBox2(float2 p, float r) {
  return length(p) - r;
}

fragmentFn(texture2d<float> tex) {
  float2 p = worldCoord / 2;

  float d = 1.0-dfBox2(float2(p.x, p.y), cos(uni.iTime) * 0.4) * 2.0;
  return float4( d * tex.sample(iChannel0, p+0.5).rgb, 1);
}


