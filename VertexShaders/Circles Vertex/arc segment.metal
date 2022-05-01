
#define shaderName arc_segment

#include "Common.h"

constant const int vc = 600;

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = vc;
}

vertexFn() {
  float2 m = float2(2, -2) * (uni.iMouse - 0.5);
  VertexOut v;
  float radius = abs(m.x);
  float end = 1.05 * (m.y) * TAU;
  v.where.xy = annulus(vid, ctrl.vertexCount / 6,  radius, 0.95, 0, end );
  v.where.zw = {0, 1};
  v.color = 1;
  return v;
}
