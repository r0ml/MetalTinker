
#define shaderName grainy_blur

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

constant const float dist = 4.0; // how far to sample from
constant const int loops = 6; // how many times to sample, more = smoother

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float4 t = float4(0.0);
  
  float2 texel = 1.0 / uni.iResolution.xy;
  float2 d = texel * dist;
  
  for(int i = 0; i < loops; i++){
    
    float r1 = clamp(rand(uv * float(i))*2.0-1.0, -d.x, d.x);
    float r2 = clamp(rand(uv * float(i+loops))*2.0-1.0, -d.y, d.y);
    
    t += tex.sample(iChannel0, uv + float2(r1 , r2));
  }
  
  t /= float(loops);
  
  return t;
}
