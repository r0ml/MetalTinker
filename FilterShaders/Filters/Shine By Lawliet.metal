
#define shaderName shine_by_lawliet

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

#define COLOR float4(1.0,1.0,1.0,0.5)
#define SPEED 0.5

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  
  float4 back = tex.sample(iChannel0,uv);
  
  float4 light = COLOR;
  
  float offset;
  
  //offset = uni.iMouse.x / uni.iResolution.x;
  
  offset = cos(mod(uni.iTime * SPEED,PI * 0.5));
  
  float a = uv.x + offset;
  
  a = a * offset;
  
  a = step(a,1.0) * a;
  
  a = max(a,0.0);
  
  a *= light.a;
  
  return back * (1.0 - a) + light * a;
  
  //fragColor = float4(offset,0.0,0.0,1.0);
}
