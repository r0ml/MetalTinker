
#define shaderName loading_2

#include "Common.h" 

struct InputBuffer {};
initialize() {}

fragmentFn() {
  float2 u = worldCoordAspectAdjusted*12.;
  float l = dot(u,u)-2.;
  float a = mod(atan2(u.y,u.x)/.785 + ceil(8.*uni.iTime) , 8.);
  return (a<1.?.843 : fract(a)<.1 ? 0.:.396) - pow(l*l,9.);
}
