
#define shaderName chrome_logo

#include "Common.h" 

fragmentFn() {
  float2 p = worldCoordAspectAdjusted / 2;

  float l = length(p),
  k = floor(mod(3. * (atan2(-p.x,p.y) + acos(min(.1 / l,1.)))/TAU-1.,3.));
  return step(l,.2) * mix( float4(k,2. - k,0,1), 1. - step(l,.08) * float4(.7,.5,0,0),  step(l,.1) );
}

 
