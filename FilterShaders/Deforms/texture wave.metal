
#define shaderName texture_wave

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  constexpr sampler iChannel0(coord::normalized, address::repeat, filter::linear);
  float2 f = textureCoord * uni.iResolution;
  f.y += sin(uni.iTime + f.x * 0.01) * 50.0;
  float2 uv = f / uni.iResolution.xy;
	return tex.sample(iChannel0, uv);
}
