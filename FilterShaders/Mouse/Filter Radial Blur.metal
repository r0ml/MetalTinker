
#define shaderName filter_radial_blur

#include "Common.h" 

struct InputBuffer {
  bool JITTER = true;
  int3 SAMPLES;
};

initialize() {
  in.SAMPLES = {2, 10, 12};
}

fragmentFn( /* device InputBuffer &in, */ texture2d<float> tex) {
  float2 uv = textureCoord;
  float3  res = float3(0);
  float radius = 1.0 / (in.SAMPLES.y * in.SAMPLES.y);
  for(int i = 0; i < in.SAMPLES.y; ++i) {
    res += tex.sample(iChannel0, uv).xyz;
    float2 d = uni.iMouse.xy-uv;
    if (in.JITTER) {
      d *= .5 + .01*rand(d* uni.iTime /* scn_frame.time */);
    }
    uv += d * radius;
  }

  return float4(res/float(in.SAMPLES.y), 1);
}
