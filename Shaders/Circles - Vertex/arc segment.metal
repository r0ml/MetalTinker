
#define shaderName arc_segment

#include "Common.h"

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  in.pipeline._1 = {3, 600, 1, 0 };
}

vertexPass(_1) {
  VertexOut v;
  float radius = abs(2 * uni.iMouse.x - 1);
  float end = 1.05 * (2 * uni.iMouse.y - 1) * TAU;
  v.where.xy = annulus(vid, in.pipeline._1.y / 6,  radius, 0.95, 0, end );
  v.where.zw = {0, 1};
  v.color = 1;
  return v;
}
