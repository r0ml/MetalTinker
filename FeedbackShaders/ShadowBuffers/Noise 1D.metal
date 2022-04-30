
#define shaderName noise_1d
#define SHADOWS 2

#include "Common.h" 

fragmentFn() {
  FragmentOutput fff;

  float2 p1 = worldCoordAspectAdjusted;
  p1.x+=2.3;
  fff.color0=lastFrame[1].sample(iChannel0,float2(0.9/length(p1),atan2(p1.y,p1.x)+0.5));

  float2 p = p1 * 4.0;
  float d = sqrt(p.x*p.x+p.y*p.y);
  d=abs(noisePerlin( float2(p.x*1.5+2.0*uni.iTime))*3+p.y-1.5);
  d=smoothstep(0.1,0.24,d);
  fff.color1 = float4(d,d,d,1.0);
  return fff;
}

