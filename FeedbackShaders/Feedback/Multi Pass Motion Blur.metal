
#define shaderName multi_pass_motion_blur

#include "Common.h" 

struct KBuffer {  };

initialize() {}


fragmentFn1() {
  FragmentOutput f;
  f.fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy / uni.iResolution.xy);
  
  // ============================================== buffers =============================
  
  f.pass1 = float4(.8,.2,.5,1);
  float2 s = uni.iResolution.xy;
  float4 h = renderInput[0].sample(iChannel0, thisVertex.where.xy / s);
  float2 g = (thisVertex.where.xy+thisVertex.where.xy-s)/s.y*1.3;
  float2
  k = float2(1.6,0) + mod(uni.iDate.w,6.28),
  a = g - sin(k),
  b = g - sin(2.09 + k),
  c = g - sin(4.18 + k);
  f.pass1 = (0.02/dot(a,a) + 0.02/dot(b,b) + 0.02/dot(c,c)) * 0.04 + h * 0.96 + step(h, f.pass1) * 0.01;
  return f;
}
