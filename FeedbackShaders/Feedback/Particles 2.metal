
#define shaderName particles_2

#include "Common.h" 

initialize() {}


fragmentFn1() {
  FragmentOutput f;
  f.fragColor = texelFetch(renderInput[0], int2(thisVertex.where.xy),0);
  
  // ============================================== buffers =============================
  
  f.pass1.xy = uni.iResolution;
  f.pass1.z = 1;
  float2 v = (thisVertex.where.xy+thisVertex.where.xy-f.pass1.xy)/f.pass1.y, r;
  f.pass1 *= renderInput[0].sample(iChannel0, thisVertex.where.xy/f.pass1.xy) / length(f.pass1);
  r.x = uni.iTime;
  r.y = length(v) * 5. + sin(r.x*.5) * 9.;
  r.x += atan2(v.x, v.y) * 5.;
  r = fract(r) - .5;
  f.pass1 += .001/dot(r, r);
  f.pass1.w = 1;
  
  return f;
}
