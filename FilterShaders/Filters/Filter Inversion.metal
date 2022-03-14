
#define shaderName filter_inversion

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float m = uni.iMouse.x ;
  
  float l = smoothstep(0., 1. / uni.iResolution.y, abs(m - uv.x));
  
  float3 cf = 1 - tex.sample(iChannel0, uv).xyz;
  float3 cl = tex.sample(iChannel0, uv).xyz;
  float3 cr = (uv.x < m ? cl : cf) * l;
  
  return float4(cr, 1);
}
