
#define shaderName simple_night_vision_effect

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  
  float lum = cos(thisVertex.where.xy.y);
  lum*=lum;
  lum/=3.;
  lum+=0.6+rand(uv*uni.iTime)/6.;
  
  float col = dot(tex.sample(iChannel0,uv).rgb,float3(0.65,0.3,0.1)*lum);
  
  return float4(0,col,0,1.)*smoothstep(0.9,0.,distance(uv,float2(0.5)));
}
