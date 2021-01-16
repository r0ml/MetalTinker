
#define shaderName Ball_Bounce

#include "Common.h" 

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  in.pipeline._1 = {3, 150, 1, 0};
}

vertexPass(_1) {
  float radius = 0.1;
  VertexOut v;
  v.where.xy = polygon(vid, in.pipeline._1.y / 3, radius );
  v.where.zw = {0, 1};
  v.color = {0.4 , 0.5, 0.6, 1};

  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  float2 ctr = abs(float2( mod(uni.iTime, 2 * (1 - radius) ) - (1 - radius), 0.6 * sin(uni.iTime*5.))) - 0.5 + radius / 2 ;
  v.where.xy = v.where.xy + 2 * ctr;

  return v;
}
