
#define shaderName polar_3

#include "Common.h" 
struct InputBuffer {
  struct {
    int _1 = 1;
    int _2 = 0;
    int _3 = 0;
  } variant;
};

initialize() {
}

fragmentFn() {
  float2 U = worldCoordAspectAdjusted;
  float l = 25 * length(U);
  
  float      L = in.variant._2 ? ceil(l) * 6. : exp2(floor(log2(l))) * 9.;
  
  float       a = atan2(U.x,U.y) - uni.iTime * ( in.variant._2 ? 2 * fract(10000 * sin(L)) - .5 : floor(l-5.)/2.) ;
  
  float4 fragColor = (!in.variant._3) * (.6 + .4* cos(  (in.variant._2 ? 0 :  floor(l)) +floor(fract(a/TAU)*L) + float4(0,23,21,0) ) );
  return fragColor - ((in.variant._3 ? -1 : 1) * max(0., 9.* max( cos( TAU *l ), cos( a*L  )) - 8. ));
}
