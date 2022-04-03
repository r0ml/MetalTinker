
#define shaderName fresnel_distortion

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  const float ring = 5.0;
  const float div = 0.5;
  float2 res = uni.iResolution.xy;
  float aspect = res.x / res.y;

  float2 uv = textureCoord;
  float t = uni.iTime * 0.05;
  
  float2 p = float2(uv.x * aspect, uv.y);
  
  float r = distance(p, float2(uni.iMouse.x * aspect, uni.iMouse.y));
  r -= t;
  r = fract(r*ring)/div;
  
  uv = -1.0 + 2.0 * uv;
  uv *=  r;
  uv = uv * 0.5 + 0.5;

  return tex.sample(iChannel0, uv);
}
