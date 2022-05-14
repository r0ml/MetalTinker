
#define shaderName hexagonal_tiling_3

#include "Common.h" 

fragmentFunc() {
  float2 U  = textureCoord * nodeAspect * float2x2(1,-1./1.73, 0,2./1.73) *5.;  // conversion to
  float3 g = float3(U, 1.-U.x-U.y), g2;                     // hexagonal coordinates
  
  g = fract(g);                                         // diamond coords
  g2 = abs(2.*g-1.);                                    // distance to borders
  
  return sin(20.*length(1.-g2)-2.*scn_frame.time);
  //O = sin(20.*length(2.-mod(.3*uni.iTime,4.)-g2))  +O-O;  // variant
}
