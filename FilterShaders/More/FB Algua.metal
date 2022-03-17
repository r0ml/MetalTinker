
#define shaderName fb_algua

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float amp = 0.1; //amplitude
  float speed = 1.0;
  
  float2 uv = textureCoord;

  float xpos = uv.x+(1.0-uv.y)*amp*sin(uv.y+uni.iTime*speed);
  
  return tex.sample(iChannel0, float2(xpos, uv.y));
}