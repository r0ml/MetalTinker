
#define shaderName simple_eclipse

#include "Common.h" 

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  float d = length(uv);
  float plt =0.5 + sin(uni.iTime)/6.0;
  float plt2=0.06 + sin(uni.iTime+PI)/40.0;
  float r1 = 0.5;
  float r2 = 0.3;
  float c2= smoothstep(r2,r2-plt2,d);
  float c1 = smoothstep(r1,r1-plt,d);
  return float4(float3(c1-c2),1.0);
}


