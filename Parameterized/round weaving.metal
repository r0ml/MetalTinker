
#define shaderName round_weaving

#include "Common.h" 

struct InputBuffer {
    bool flat = false;
};

initialize() { }


static void BBB(float v, bool c, float s, thread float4& fragColor, bool flat) {
  if ( c ? abs(v)/.1 > 3 : abs(v)/.1 < 1 ) {
    float gg =  mix ( ( .5+.5* cos(2.5 * TAU * abs((v)*6.))  ) ,  smoothstep(0., 0.3, cos( 2.5 * TAU * abs(v)*6. ) + 1. ) , flat );
    fragColor += (1.-fragColor) * gg * (.5+.5*s);
  }
}

fragmentFn() {
  float2 U = worldCoordAspectAdjusted;

  float a = atan2(U.y,U.x);
  float l = length(U);
  
  float4 fragColor = 0;
  
  BBB( U.y, false , -cos(2.5 * TAU * abs(U.x) ), fragColor, in.flat );                 // horizontal
  BBB( U.x, false , -cos( 2.5 * TAU * max(.2,abs(U.y))), fragColor, in.flat );    // vertical
  
  if ( l/.1 > 2. ) {
    U = U * float2x2(1/1.4,-1/1.4,1/1.4,1/1.4);              // diagonal
    BBB( U.y, false , cos(2.5 * TAU * abs(U.x)) , fragColor, in.flat);
    BBB( U.x, false , cos(2.5 * TAU * abs(U.y)) , fragColor, in.flat);
  }
  
  BBB( l, true , cos(a*4.) * sign( cos(2.5 * TAU * abs(l) )), fragColor, in.flat );    // circular  variant : > 1. or > 1.6
  
  fragColor = .1+.9 * fragColor;
  //O = sqrt(O);
  fragColor.r *= 1.2;
  return fragColor;
}
