
#define shaderName Sliding_Bar

#include "Common.h" 

struct InputBuffer {
  struct {
    int3 _1;
  } pipeline;
};
initialize() {
  in.pipeline._1 = {4,4,1};
}

vertexPass(_1) {
  VertexOut v;
  v.where.x = 0.1 * (2 * step( float(vid), 1) - 1);
  v.where.y = 1-2*fmod(float(vid), 2);

  v.where.x += sin(uni.iTime) * 0.9;

  v.where.zw = {0, 1};

  v.color =  {0.8, 0.9, 0.7, 1};
  return v;
}
