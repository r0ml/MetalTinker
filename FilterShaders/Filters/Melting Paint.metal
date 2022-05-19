
#define shaderName melting_paint

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 p = textureCoord;
  p.y += .01 * fmod(scn_frame.time, 15) * fract(sin(dot(float2(p.x), float2(12.9, 78.2)))* 437.5);
  
  return tex.sample(iChannel0, p);
}

