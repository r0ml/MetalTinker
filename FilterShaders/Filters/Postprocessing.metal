
#define shaderName Postprocessing

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float2 q = textureCoord;
  float2 uv = 0.5 + (q-0.5)*(0.9 + 0.1*sin(0.2*uni.iTime));
  
  float3 oricol = tex.sample( iChannel0, q).xyz;
  float3 col;
  
  col.r = tex.sample(iChannel0,float2(uv.x+0.003,uv.y)).x;
  col.g = tex.sample(iChannel0,float2(uv.x+0.000,uv.y)).y;
  col.b = tex.sample(iChannel0,float2(uv.x-0.003,uv.y)).z;
  
  col = saturate(col*0.5+0.5*col*col*1.2);
  
  col *= 0.5 + 0.5*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);
  
  col *= float3(0.95,1.05,0.95);
  
  col *= 0.9+0.1*sin(10.0*uni.iTime+uv.y*1000.0);
  
  col *= 0.99+0.01*sin(110.0*uni.iTime);
  
  float comp = smoothstep( 0.2, 0.7, sin(uni.iTime) );
  col = mix( col, oricol, saturate(-2.0+2.0*q.x+3.0*comp) );
  
  return float4(col,1.0);
}
