
#define shaderName faded_edge

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float EDGE = .2;
  
  float2 uv = textureCoord;
  float edge = EDGE * abs(sin(scn_frame.time / 5.));
  
  float4 fragColor = tex.sample(iChannel0, uv);
  fragColor *= (smoothstep(0., edge, uv.x)) * (1. - smoothstep(1. - edge, 1., uv.x));
  fragColor *= (smoothstep(0., edge, uv.y)) * (1. - smoothstep(1. - edge, 1., uv.y));
  fragColor.w = 1;
  return fragColor;
}
