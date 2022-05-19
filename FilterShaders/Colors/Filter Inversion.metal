
#define shaderName filter_inversion

#include "Common.h" 

fragmentFunc(texture2d<float> tex, device float2& mouse) {
  float2 uv = textureCoord;
  float m = mouse.x ;
  
  float l = smoothstep(0., scn_frame.inverseResolution.y, abs(m - uv.x));
  
  float3 cf = 1 - tex.sample(iChannel0, uv).xyz;
  float3 cl = tex.sample(iChannel0, uv).xyz;
  float3 cr = (uv.x < m ? cl : cf) * l;
  
  return float4(cr, 1);
}
