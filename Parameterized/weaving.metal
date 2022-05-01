
#define shaderName weaving

#include "Common.h" 

struct InputBuffer {
    bool isb = true;
    bool serge = false;
    struct {
      int stringy;
      int satin;
    } variant;
};

initialize() {
  in.variant.stringy = 1;
}


static float S1(float x,float y, float s, bool b4, bool serge) { // serge
  if (abs(fract(x)-.5) > .4 ) {
    return 0;
  } else {
    float j = y + ceil(x);
    if (serge) {
      j = 0.5 * ( y + s - ceil(x));
    }
    if (b4) {
      j += .2 * fract(100 * sin(x * 100));
    }
    return .7 + .3 * sinpi( j );
  }
}

static float S2(float x,float y,float a,float b) {
  return abs(fract(x)-.5) < .4  ? a + b * sin(pi/2.5* ( y -.25 + 3.*ceil(x) )) : 0.;
}

fragmentFn() {
  float2 U = textureCoord * aspectRatio * 30.;
  if (in.variant.stringy) {
    bool b4 = in.isb;
    bool serge = in.serge;
    
    return max (
                S1( U.x,U.y, 0, b4, serge) ,
                S1( ( 2 * serge - 1) * U.y , U.x, 1, b4, serge) )
    * ( 1 + b4 * float4( .1, 0, -.1, 0 ) );
  } else if (in.variant.satin) {
    return max ( S2(U.x,U.y,.5,.5), S2(U.y,-U.x,.8,-.2) );
  }
  return 0;
}
