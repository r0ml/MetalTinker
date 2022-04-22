
#define shaderName filter_motion_blur_multipass

#include "Common.h" 

#define BLUR .9

fragmentFn(texture2d<float> tex, texture2d<float> lastFrame) {
  float2 u = thisVertex.where.xy / uni.iResolution;
  float4 fragColor = mix(tex.sample(iChannel0, u), lastFrame.sample(iChannel0, u), clamp(BLUR,0.,1.-1e-2));
  fragColor.w = 1;
  return fragColor;
}
