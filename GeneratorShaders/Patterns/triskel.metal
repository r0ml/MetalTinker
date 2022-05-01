
#define shaderName triskel

#include "Common.h" 

struct InputBuffer {};
initialize() {}

fragmentFn() {
  float2 U = worldCoordAspectAdjusted + float2(0,.1);
  
  float a = -floor((atan2(U.y,U.x)-.33)*3./tau)/3.*tau -.05, l; // 3 symmetries
  U *= float2x2(cos(a),-sin(a),sin(a),cos(a));
  U = 3.*(U-float2(0,.577));
  
  l = length(U), a = atan2(U.y,U.x);                        // spiral
  float4 fragColor = float4( l + fract((a+2.25)/tau) < 2. ? .5+.5*sin(a+tau*l) : 0.);
  
  return smoothstep(.0,.1,abs(fragColor-.5)) - smoothstep(.8,.9,fragColor);   // optional decoration
}
