
#define shaderName particles

#include "Common.h" 

initialize() {}


fragmentFn() {
  // ============================================== buffers =============================

  float4 f = 0;
  f.xy = uni.iResolution;
  f.z = 1;
  float2 v = (thisVertex.where.xy+thisVertex.where.xy-uni.iResolution)/uni.iResolution.y;
  float2 k;
  f = renderInput[0].sample(iChannel0, thisVertex.where.xy/uni.iResolution) / length(uni.iResolution);
  float2 g = 0;
  for( g = 0 ; g.x<TAU; g+=.01) {
    k = v - sin(g + float2(1.6,0)) * fract(uni.iTime*.1+4.*sin(g*6.))*3.;
    f += 1e-5 / dot(k,k);
  }
  return f;
}
