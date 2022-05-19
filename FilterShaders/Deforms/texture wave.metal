
#define shaderName texture_wave

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  constexpr sampler iChannel0(coord::normalized, address::repeat, filter::linear);
  float2 f = textureCoord ;
  f.y += sin(scn_frame.time + f.x * 20) / 20;
  float2 uv = f ;
	return tex.sample(iChannel0, uv);
}
