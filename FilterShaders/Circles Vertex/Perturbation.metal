
#define shaderName perturbation

#include "Common.h" 

static float hash11(float p) {
  float3 p3  = fract(float3(p) * 443.8975);
  p3 += dot(p3, p3.yzx + 19.19);
  return 2.0*fract((p3.x + p3.y) * p3.z)-1.0;
}

static float noise(float t) {
  float i = floor(t);
  float f = fract(t);
  
  return mix(hash11(i) * f, hash11(i+1.0) * (f - 1.0), f);
}

fragmentFn() {
  float2 coord = worldCoordAspectAdjusted;
  
  float2 delta = float2(noise(uni.iTime), noise(uni.iTime+60.0)) * abs(noise(20.0*uni.iTime));
  
  float rho2c = dot(coord-delta,coord-delta);
  float rho2m = dot(coord,coord);
  float rho2y = dot(coord+delta,coord+delta);
  
  float3 cmy = float3(rho2c, rho2m, rho2y) - 0.2;
  cmy = 0.0025/(cmy*cmy);
  
  return float4(float3(1.00) - cmy,1.0);
}
