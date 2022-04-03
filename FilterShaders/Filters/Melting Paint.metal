
#define shaderName melting_paint

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float2 p = textureCoord;
  p.y += .01 * fmod(uni.iTime, 15) * fract(sin(dot(float2(p.x), float2(12.9, 78.2)))* 437.5);
  
  return tex.sample(iChannel0, p);
}

