
#define shaderName starburst

#include "Common.h" 

constant const float4 f1 = float4(1,   0.3,   0, 1);
constant const float4 f2 = float4(0.3, 0.2, 0.5, 1);

fragmentFn( texture2d<float> lastFrame ) {
  float t = uni.iTime;

  float2 s = uni.iResolution.xy;
  float2 u = (thisVertex.where.xy+thisVertex.where.xy-s)/s.y;
  float2 ar = float2( atan2(u.x, u.y) * 3.18 + t*2., length(u)*3. + sin(t*.5)*10.);

  float p = floor(ar.y)/5.;
  ar = abs(fract(ar)-.5);

  float4 lf = lastFrame.sample(iChannel0, thisVertex.where.xy / s);
  return lf * 0.9 + mix( f1 , f2, float4(p)) * 0.01/dot(ar,ar);

}
