
#define shaderName twirl_effect

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  // float2 mo = uni.iMouse.xy;

  float speed = 0.8;
  float t0 = uni.iTime*speed;
  float t1 = sin(t0*2.);
  // float t2 = 0.5*t1+0.5;

  // float t = t2;

  //twirl effect
  float thetascale = 1.;
  float radius = t1*0.4+0.6;
  float2 dxy = uv - 0.5;
  float r = length(dxy);
  float beta = atan2(dxy.y,dxy.x) + thetascale*(radius-r)/radius;

  float2 uvt = 0.5+r*float2(cos(beta),sin(beta));
  
  return tex.sample(iChannel0, uvt);
}
