
#define shaderName filter_gamma_correction

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

constant const float GAMMA = 2.2;

fragmentFn(texture2d<float> tex) {
  float m = uni.iMouse.x ;
  float2 b = textureCoord;
  
  float l = smoothstep(0., 1. / uni.iResolution.y, abs(m - b.x));
  
  float3 cl = tex.sample(iChannel0, b).rgb;
  float3 cf = pow( cl, 1. / GAMMA);
  float3 cr = (b.x < m ? cl : cf) * l;
  
  return float4(cr, 1);
}

 
