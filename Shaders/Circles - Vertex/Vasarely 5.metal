
#define shaderName vasarely_5

#include "Common.h"

struct InputBuffer {};
initialize() {}

fragmentFn() {
  float2  R = uni.iResolution.xy, V;
  float2 U = worldCoordAspectAdjusted * 2.;
  V = ceil(U+float2(.5,0));
  float e = 10./R.y, l=U.y,
  t = uni.iTime;
  
  float4 O = 0;
  if (abs(U.x)>1.5) { O+=.3; return O;}
  U += float2(.5,0.);
  
  if (l > 1.) {                         // top area
    U += U;
    O += 1.- smoothstep(e, -e, length(U+float2(-1, -3.1)) - 0.6);
    O -= smoothstep(e, -e, length(U+float2(1, -2)) - 0.3) + smoothstep(e, -e, length(U+float2(-3, -2))-0.3);
    return O;
  }
  
  //       tiles              rotation
  U = 2.*fract(U)-1.;
  if (fract(t/acos(-1.))<.5) {
    float4 xx = sin( t*(2.*mod(V.x+V.y,2.)-1.) + 1.57*float4(1,2,0,1));
    U *= float2x2(xx.x, xx.y, xx.z, xx.w  );
  }
  
  O +=   smoothstep(e,-e, length(U)-0.9) - smoothstep(e, -e, length(U)-0.3);  // white disk + central dot
  
  O -=   smoothstep(e, -e, length(U+float2(-1,0))-0.3) + smoothstep(e, -e, length(U+float2(1,0)) - 0.3)    // rotating dots
  + smoothstep(e, -e, length(U+float2(0, -1))-0.3) + smoothstep(e, -e, length(U+float2(0, 1))-0.3);
  
  return O;
}
