
#define shaderName fresnel_distortion

#include "Common.h" 

fragmentFunc(texture2d<float> tex, constant float2& mouse) {
  const float ring = 5.0;
  const float div = 0.5;
  float2 aspect = nodeAspect;

  float2 uv = textureCoord;
  float t = scn_frame.time * 0.05;
  
  float2 p = uv * aspect;
  
  float r = distance(p, mouse*aspect);
  r -= t;
  r = fract(r*ring)/div;
  
  uv = -1.0 + 2.0 * uv;
  uv *=  r;
  uv = uv * 0.5 + 0.5;

  return tex.sample(iChannel0, uv);
}
