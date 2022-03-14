
#define shaderName one_pass_blur

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  
  float hor = 1. / uni.iResolution.x;
  float ver = 1. / uni.iResolution.y;
  const float iter = 5.;
  
  
  float4 pic = tex.sample(iChannel0,uv)/(iter * 10.);
  
  for (float i = 0.;i < iter;i++)
  {
    pic += tex.sample(iChannel0,uv+float2(hor*i,0.0)) / (iter * 10.);
    pic += tex.sample(iChannel0,uv+float2(-hor*i,0.0)) / (iter * 10.);
    pic += tex.sample(iChannel0,uv+float2(0.0,ver*i)) / (iter * 10.);
    pic += tex.sample(iChannel0,uv+float2(0.0,-ver*i)) / (iter * 10.);
    
    pic += tex.sample(iChannel0,uv+float2(hor*i,ver*i)) / (iter * 10.);
    pic += tex.sample(iChannel0,uv+float2(-hor*i,ver*i)) / (iter * 10.);
    pic += tex.sample(iChannel0,uv+float2(hor*i,-ver*i)) / (iter * 10.);
    pic += tex.sample(iChannel0,uv+float2(-hor*i,-ver*i)) / (iter * 10.); 
  }
  
  return float4(pic);
}
