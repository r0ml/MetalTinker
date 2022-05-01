
#define shaderName rosette

#include "Common.h" 

struct InputBuffer {
    bool plural = false;
};

initialize() {}


static float D(float2 U, float2 d) {
  return .005 / abs( length( mod(U,d+d) -d ) -d.x ) ;
}

fragmentFn() {
  float2 U = worldCoordAspectAdjusted;
  float4 fragColor = 0;
  if (in.plural) {
    U = 2.*U;
    float2 d = float2(.58,1);
    for ( int i = 0; i < 5; i++) {
      U.x += d.x;
      fragColor += D(U,d);
      U += d*.5;
      fragColor += D(U,d);
    }
  } else {
    float2 i = 0;
    float uu = dot(U,U);
    if (uu < 1.02) for ( ; i.x<7. ; i += 1.05 ) {
      fragColor += .004/ abs( length( U - sin(i) ) - 1. );
      i.y = 33+i.x;
    }
  }
  return fragColor;
}
