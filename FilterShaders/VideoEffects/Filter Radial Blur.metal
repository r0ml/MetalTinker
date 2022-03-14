
#define shaderName filter_radial_blur

#include "Common.h" 

struct InputBuffer {
  bool JITTER = true;
};

initialize() {
}

/*
 #define MOUSE

 #ifdef MOUSE
 #define CENTER (uni.iMouse.xy)
 #else
 #define CENTER float2(.5)
 #endif
 */

constant const int SAMPLES = 10;
constant const float RADIUS = .01;

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float3  res = float3(0);
  for(int i = 0; i < SAMPLES; ++i) {
    res += tex.sample(iChannel0, uv).xyz;
    float2 d = uni.iMouse.xy-uv;
    if (in.JITTER) {
      d *= .5 + .01*rand(d*uni.iTime);
    }
    uv += d * RADIUS;
  }

  return float4(res/float(SAMPLES), 1);
}
