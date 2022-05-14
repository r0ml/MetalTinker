
#define shaderName soft_shadows_through_holes

#include "Common.h" 

fragmentFunc() {
  float h = .01 + .6*(.5+.5* scn_frame.sinTime);    // distance occluder-screen
  float r = .3;                             // holes radius

  
  float2 U = textureCoord * nodeAspect * 4.;
  
  float4 fragColor = 0;
  
  U.x -= .5 * mod(floor(U.y),2.);
  U = fract( U ) - .5;                      // local coordinates % hole center
  
  for (int k=0; k<25; k++) {                // accounts for center + neighbor cells
    float2 P = float2(k % 5 - 2, k / 5 - 2);
    P.x -= .5 * mod(floor(P.y),2.);       // hole center
    float d = length( U-P ),              // distance to it
    a = atan2(h, d - r) - atan2(h, d + r);  // hole (thus sky) apperture from pixel on screen
    a *= a;                               // solid angle = PI.(a/2)²
    fragColor +=  a / 2; // hole (thus sky) solid angle / 2Pi from pixel on screen
  }
  return fragColor;
}
