
#define shaderName trainpoints

#include "Common.h" 

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted;
  uv*=0.1 + 1.5*(0.5+0.5*sin(0.3*uni.iTime));
  
  float vel = 0.1;
  float2 uvrot = uv;
  uvrot.x = cos(vel*uni.iTime)*uv.x + sin(vel*uni.iTime)*uv.y;
  uvrot.y = -sin(vel*uni.iTime)*uv.x + cos(vel*uni.iTime)*uv.y;

  uv = uvrot;
  
  float radius = 0.6;
  float offset = 0.01;
  float freq = 3.0;

  float2 fuv = sin(freq * 2 * PI * uv);
  float2 mask = 2 * smoothstep( 0 , 0, fuv ) - 1;

  float t = mod(uni.iTime,4.0);

  if(t<1.0){
    uv.x += smoothstep(0, 1, t)*mask.y;
  }else if(t<2.0){
    uv.y += smoothstep(0, 1, t-1.0)*mask.x;
  }else if(t<3.0){
    uv.x -= smoothstep(0, 1, t-2.0)*mask.y;
  }else if(t<4.0){
    uv.y -= smoothstep(0, 1, t-3.0)*mask.x;
  }
  
  float f = 1.0-smoothstep(radius - offset, radius + offset, abs( fuv.x * fuv.y) );

  return float4(f,f,f,1.0);
  
}
