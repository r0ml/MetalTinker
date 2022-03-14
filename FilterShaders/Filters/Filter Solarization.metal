
#define shaderName filter_solarization

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

constant const float3 THRESHOLD = float3(1.,.92,.1);

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float m = uni.iMouse.x ;
  
  float l = smoothstep(0., 1. / uni.iResolution.y, abs(m - uv.x));
  
  float3 cl = tex.sample(iChannel0, uv).xyz;
  float3 cf = cl;
  bool3 cfb = cf < THRESHOLD;
  cf =  float3(cfb) + sign(0.5 - float3(cfb) ) * cf;
  float3 cr = (uv.x < m ? cl : cf) * l;
  
  return float4(cr, 1);
}
