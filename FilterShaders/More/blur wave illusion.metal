
#define shaderName blur_wave_illusion

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}


fragmentFn(texture2d<float> tex) {
  constexpr sampler iChannel0(coord::normalized, address::repeat, filter::linear);
  float2 u = textureCoord;
  float t = uni.iTime,
        l = .5+.5*sin(TAU*(length(u)-t));
  return float4( tex.sample(iChannel0, u,2.*l).rgb, 1);
}

 
