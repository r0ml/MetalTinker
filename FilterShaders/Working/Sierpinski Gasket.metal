
#define shaderName sierpinski_gasket

#include "Common.h" 

struct KBuffer {  };
initialize() {}

 
static float2 randx(float t, float tw) {
    float4 v = float4(.5,.9,.1,fract(cos(tw+t)*43758.5453)*3.);
    return v.w < 1. ? v.xy : (v.w < 2. ?  v.zz : v.yz);
}

fragmentFn1() {
  FragmentOutput f;
  f.fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy / uni.iResolution.xy);

 // ============================================== buffers ============================= 

  float tw = fract(uni.iTime);
    float2 v, e = randx(0., tw);
    for (float i = 0.; i < 5e2; ++i) {
        e = mix(randx(i, tw), e, .5);
        v = e - thisVertex.where.xy / uni.iResolution;
        if (dot(v,v) < 1e-6) {
          f.pass1 = 1;
          return f;
        }
        
    }	
  f.pass1 = renderInput[0].read(uint2(thisVertex.where.xy));
  return f;
}
