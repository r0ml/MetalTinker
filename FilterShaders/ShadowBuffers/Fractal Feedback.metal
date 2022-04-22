
#define shaderName fractal_feedback

#include "Common.h" 

static float2x2 mat2x(float4 x) { return float2x2(x.xy, x.zw); }

fragmentFn(texture2d<float> lastFrame) {

  float4 fragColor = lastFrame.sample(iChannel0, fract((thisVertex.where.xy)/uni.iResolution.xy) / 15.0 +1. )/thisVertex.where.xy.xyyx;

  fragColor = mix( lastFrame.sample( iChannel0, fract((thisVertex.where.xy+mat2x(cos(uni.iTime*.5+uni.iMouse.x*uni.iResolution.x*.01+float4(.0,1.6,-1.6,.0)))*(thisVertex.where.xy-3e2)+3e2)/uni.iResolution.xy)) / 15 , sin(fragColor.yxwz), .1);
  
  return 15 * fragColor;
}
