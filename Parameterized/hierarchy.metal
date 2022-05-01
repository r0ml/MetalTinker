
#define shaderName hierarchy

#include "Common.h" 
struct InputBuffer {
    bool kaleidoscope = false;
    bool roll = false;
};

initialize() {
}

static float endC(float2 V, float2 U, float2 A, InputBuffer in) {
  if (in.kaleidoscope || in.roll) {
    return pow(dot(V,1), 1/A.x);
  } else {
    return length(U);
  }
}

fragmentFn() {
  float4 incr = float4(.11,.14,.2,0);
  // without the .01, sometimes you're dividing by zero
  float2 A = 4./(1.01+sin(uni.iTime));
  float2 U = worldCoordAspectAdjusted;
  float2 s = sign(U)+float2(U.x==0, U.y==0); // I only need to do this on roll
  U = abs(U);
  float2 V = pow(U, A);
  float4 fragColor = 0;
  
  for (uint i = 0 ; i<9 && endC(V,U,A, in)<1 ; i++) {
    fragColor += incr;
    U = U/.4-1.;
    if (in.kaleidoscope || in.roll) {
      U = U * makeMat(cos(uni.iTime+float4(0,55,33,0)));
      if (in.roll) {
        U = s * U;
        s = sign(U)+float2(U.x == 0, U.y == 0);
      }
      U = abs(U);
      V = pow(U,A);
    } else {
      U = abs(U);
    }
  }
  fragColor.w = 1;
  return fragColor;
}
