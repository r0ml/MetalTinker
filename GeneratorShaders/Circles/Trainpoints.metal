
#define shaderName trainpoints

#include "Common.h" 

fragmentFunc() {
  float2 uv = worldCoordAdjusted;
  float t = scn_frame.time;
  uv*=0.1 + 1.5*(0.5+0.5*sin(0.3*t));
  
  float vel = 0.1;
  float2 uvrot = uv;
  uvrot.x = cos(vel*t)*uv.x + sin(vel*t)*uv.y;
  uvrot.y = -sin(vel*t)*uv.x + cos(vel*t)*uv.y;

  uv = uvrot;
  
  float radius = 0.6;
  float offset = 0.01;
  float freq = 3.0;

  float2 fuv = sin(freq * 2 * PI * uv);
  float2 mask = 2 * smoothstep( 0 , 0, fuv ) - 1;

  float tt = mod(t,4.0);

  if(tt<1.0){
    uv.x += smoothstep(0, 1, tt)*mask.y;
  }else if(tt<2.0){
    uv.y += smoothstep(0, 1, tt-1.0)*mask.x;
  }else if(tt<3.0){
    uv.x -= smoothstep(0, 1, tt-2.0)*mask.y;
  }else if(tt<4.0){
    uv.y -= smoothstep(0, 1, tt-3.0)*mask.x;
  }
  
  float f = 1.0-smoothstep(radius - offset, radius + offset, abs( fuv.x * fuv.y) );

  return float4(f,f,f,1.0);
  
}
