
#define shaderName fractal_feedback
#define SHADOWS 2

#include "Common.h" 

static float2x2 mat2x(float4 x) { return float2x2(x.xy, x.zw); }

fragmentFn() {

  float4 fragColor = (lastFrame[1].sample(iChannel0, fract((thisVertex.where.xy)/uni.iResolution.xy)) / 15.0 + 1. )/thisVertex.where.xyyx;

  float4 oc = lastFrame[1].sample( iChannel0, fract( (thisVertex.where.xy + mat2x(cos(uni.iTime * 0.5 + uni.iMouse.x * uni.iResolution.x * 0.01 + float4(0, 1.6, -1.6, 0)))*(thisVertex.where.xy-300)+300 )/uni.iResolution )) / 15;
  fragColor = mix( oc , sin(fragColor.yxwz), .1);
  
  FragmentOutput f;
  f.color0 = 15 * fragColor;
  f.color1 = 15 * fragColor;

  f.color0.w = 1;
  return f;
}
