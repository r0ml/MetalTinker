
#define shaderName fading_effect

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float d = 1.0-length(( textureCoord * 2 - 1) - cos(uni.iTime) * 0.4) * 2.0;
  return float4( d * tex.sample(iChannel0, textureCoord).rgb, 1);
}
