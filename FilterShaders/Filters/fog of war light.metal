
#define shaderName fog_of_war_light

#include "Common.h" 

constexpr sampler smp(coord::normalized, address::repeat, filter::linear, mip_filter::linear);

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float2 center = uni.iMouse.xy;

  float2 aspect = uni.iResolution / uni.iResolution.x;
  float size = 3;
  float d = distance( aspect * (center - 0.5) , aspect * ( uv - 0.5) ) * size;


  float4 img = gammaEncode( tex.sample(smp,uv,level( d*5.0)));
  img *= float4(1.0-d);
  img.w = 1;
  return gammaDecode(img) ;
}
