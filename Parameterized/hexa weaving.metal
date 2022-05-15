
#define shaderName hexa_weaving

#include "Common.h"

struct InputBuffer {
    struct {
      int hex1 = 1;
      int hex3 = 0;
      int oriental = 0;
    } variant;
    int3 axes;
};

initialize() { 
  in = InputBuffer();
  in.axes = { 2, 3, 7 } ;
}


fragmentFunc(device InputBuffer &in) {
  float N = in.variant.oriental ? in.axes.y : 3;              // number of axis
  
  // varying over time....
  // float N = 2.+mod(floor(iTime),6.); // number of axis
  
  float2x2 rm = rot2d(PI/N);
  float S = 8.;              // scale
  float2 U = worldCoordAdjusted / 2;

  if (in.variant.hex1 || in.variant.hex3 ) {
    U *= S;
  }

  float4 fragColor = 0;
  
  for (float i=0.; i<N; i++) {
    float ux;
    if (in.variant.hex1 == 1) {
      ux = abs(fract(U.x)-.5)-.1;
    } else if (in.variant.hex3 == 1) {
      ux = abs(fract(U.x + .1) -.6) - .2;
    } else if (in.variant.oriental) {
      ux = abs(fract(S*U.x)-.5)-.1;
    } else {
      ux = 0;
    }

    float2 reso = 1 / scn_frame.inverseResolution;
    float4 ss = smoothstep(S/reso.y, 0., ux);               // strip
    
    if (in.variant.hex1 || in.variant.hex3) {
      fragColor = max( fragColor,  ss * ( .7 + .3* sin(TAU * ( U.y*1.73/2. + .5*floor(U.x) ))) ); // waves
    } else if (in.variant.oriental) {
      fragColor += ss;
    }
    
    U *= rm;
  }
  return fragColor;
}
