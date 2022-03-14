
#define shaderName mix3textures

#include "Common.h" 

struct InputBuffer {
};

initialize() {
//  setTex(0, asset::bubbles);
//  setTex(1, asset::rust);
//  setTex(2, asset::arid_mud);
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1, texture2d<float> tex2) {
  float2 uv = textureCoord;
  
  float4 final_color = float4(0.);
  float weight0 = uni.iMouse.x;
  float weight1 = uni.iMouse.y;
  float weight2 = 1.0 - weight0 - weight1;
  final_color = tex0.sample(iChannel0,   uv) * weight0 +
  tex1.sample(iChannel0, uv) * weight1 +
  tex2.sample(iChannel0, uv) * weight2;
  float dist = distance(uv, float2(0.5)),
  falloff = uni.iMouse.y < 0.01 ? 0.1 : uni.iMouse.y ,
  amount = uni.iMouse.x < 0.01 ? 1.0 : uni.iMouse.x ;
  final_color *= smoothstep(0.8, falloff * 0.8, dist * (amount + falloff));
  
  return final_color;
}
