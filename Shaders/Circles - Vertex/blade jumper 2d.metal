
#define shaderName blade_jumper_2d

#include "Common.h" 

struct InputBuffer { };
initialize() {}




fragmentFn() {
  float2 g = worldCoordAspectAdjusted; 
  // could multiply by uni.iResolution.x / uni.iResolution.y
  float2 u = float2(fix_atan2(g.y,g.x)/PI-.5,length(g)-.5);
  float t = fract(uni.iTime);
  return min(length(g+float2(0,pow(t*2.-max(t*4.-2.,0.), 2.)*.27-.5))-.04, u.y+floor(u.x*2.+t)*.2-t*.2+.4)*length(uni.iResolution*.2);
}
