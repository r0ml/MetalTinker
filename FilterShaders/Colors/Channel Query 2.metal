
#define shaderName channel_query_2

#include "Common.h" 

struct InputBuffer {
    struct {
      int _0 = 0;
      int _1 = 0;
      int _2 = 1;
    } channel;
};

initialize() {
  in.channel._0 = 0;
  in.channel._1 = 0;
  in.channel._2 = 1;
}

fragmentFn(texture2d<float> tex) {
  float x = dot(tex.sample(iChannel0, textureCoord), float4( in.channel._0, in.channel._1, in.channel._2, 0));
  return float4(x, x, x, 1);
}
