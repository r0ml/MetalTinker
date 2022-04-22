
#define shaderName spirograph_in_the_wish_dasher

#include "Common.h" 

struct KBuffer {
};
initialize() {}


fragmentFn1() {
  FragmentOutput f;
	f.fragColor = renderInput[0].read( uint2(thisVertex.where.xy));


  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
    float4 old = renderInput[0].read(uint2( thisVertex.where.xy ) ); // buffer

    float d = .3 + .15 * sin(uni.iTime * 3.);
    float t2 = uni.iTime * 2. + sin(uni.iTime * .03 + 2.);
    float2 pen = float2(
        d * cos(t2) * uni.iResolution.y/uni.iResolution.x,
    	d * sin(t2)
    ) + .5;
    
    float dis = distance(uv, pen) / .2;
    if(dis < 1.) {
      	f.pass1 = old + pow(1.-dis, 20.) * .05;
    } else {
        f.pass1 = old;
    }
    //clear
    //O = float4(0.);
   f.pass1.w = 1;
  return f;
}
