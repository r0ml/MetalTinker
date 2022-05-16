
#define shaderName filter_solarization

#include "Common.h" 

constant const float3 THRESHOLD = float3(1.,.92,.1);

fragmentFunc(texture2d<float> tex, device float2& mouse) {
  float2 uv = textureCoord;
  float m = mouse.x ;
  
  float l = smoothstep(0., scn_frame.inverseResolution.y, abs(m - uv.x));
  
  float3 cl = tex.sample(iChannel0, uv).xyz;
  float3 cf = cl;
  bool3 cfb = cf < THRESHOLD;
  cf =  float3(cfb) + sign(0.5 - float3(cfb) ) * cf;
  float3 cr = (uv.x < m ? cl : cf) * l;
  
  return float4(cr, 1);
}
