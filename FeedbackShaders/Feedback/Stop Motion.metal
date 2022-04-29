
#define shaderName stop_motion

#include "Common.h" 

struct InputBuffer {
  bool blur = false;
  int3 frameInterval;
};

initialize() {
  in.frameInterval = int3(15, 15, 60);
}

fragmentFn(texture2d<float> lastFrame, texture2d<float> tex) {
  int d = in.frameInterval.y;
  int e = uni.iFrame;
  int m = e % d;

  float4 buf = lastFrame.read(uint2(thisVertex.where.xy));
  float4 bri = tex.sample(iChannel0, (thisVertex.where.xy+0.5) / uni.iResolution.xy);

  return mix( buf, bri, mix(in.blur * 0.1, 1, m == 0) );
}
