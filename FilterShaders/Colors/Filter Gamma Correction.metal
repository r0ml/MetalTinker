
#define shaderName filter_gamma_correction

#include "Common.h" 

constant const float GAMMA = 2.2;

fragmentFunc(texture2d<float> tex, device float2& mouse) {
  float m = mouse.x ;
  float2 b = textureCoord;
  
  float l = smoothstep(0., scn_frame.inverseResolution.y , abs(m - b.x));
  
  float3 cl = tex.sample(iChannel0, b).rgb;
  float3 cf = pow( cl, 1. / GAMMA);
  float3 cr = (b.x < m ? cl : cf) * l;
  
  return float4(cr, 1);
}

 
