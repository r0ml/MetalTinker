
#define shaderName rainbow_group

#include "Common.h" 

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted + float2(0, 1);

  float theta = atan2(uv.y, uv.x);
  float r = length(uv);
  float rainbow = floor(r*7.);
  
  float4 fragColor = float4(1.)*mod(rainbow+1.,2.);
  fragColor += float4( (float4(rainbow) == float4(5.,3.,1., 0.)));
  
  theta += uni.iTime/5.*mod(7.-rainbow,7.);
  
  if(mod(theta, pi) > pi/2.){
    fragColor = float4(1.-fragColor.w);
  }
  return fragColor;
}
