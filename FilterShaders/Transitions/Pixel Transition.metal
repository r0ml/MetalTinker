
#define shaderName pixel_transition

#include "Common.h" 
struct InputBuffer {
};

initialize() {
//  setTex(0, asset::bubbles);
//  setTex(1, asset::london);
//  setTex(2, asset::lichen);
//  setTex(3, asset::stars);
}

 


fragmentFn(texture2d<float> tex0, texture2d<float> tex1, texture2d<float> tex2, texture2d<float> tex3) {
  float2 pixel_count = max(floor(uni.iResolution * (cos(uni.iTime) + 1.0) / 2.0), 1.0);
  float2 pixel_size = uni.iResolution / pixel_count;
  float2 pixel = pixel_size * ( 0.5 + floor(thisVertex.where.xy / pixel_size));
  float2 uv = pixel / uni.iResolution;
  
  uint x = uint((uni.iTime + PI) / TAU) % 4;
  texture2d<float> t;
  if (x == 0) {
    t = tex0;
  } else if (x == 1) {
    t = tex1;
  } else if (x == 2) {
    t = tex2;
  } else if (x == 3) {
    t = tex3;
  }
  return float4(t.sample(iChannel0, uv).rgb, 1);
}



