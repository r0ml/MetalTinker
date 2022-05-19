
#define shaderName grate

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 uv = textureCoord * nodeAspect;
  
  float tile = 200.0;
  float2 oo = sin(uv*tile + float2(0.0,scn_frame.time*10.0))*0.5 + 0.5;
  float doo = smoothstep(0.2, 0.8, 1.0 - dot(oo, float2(1.0)));
  
  return tex.sample(iChannel0, uv / nodeAspect)*doo;
}
