
#define shaderName arcs

#include "Common.h"

static float rds(float x) {
  return -1 + 2 * step(0.5,rand(x));
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  float r = length(uv) * 50;
  float ri = floor(r);
  float sg = floor(10.+rand(ri)*10.0);
  float sp = rds(ri*15.)*(.1+.4*rand(ri*70.));
  float a = floor(fract(atan2(uv.y,uv.x)/TAU+uni.iTime*sp)*sg);
  float c = step(0.7, rand(a + ri * 40));
  c *= smoothstep(-0.9, -0.85, sin(uni.iTime * rand(ri * 85)));
  c *= step(0.2, fract(r));
  c *= step(2, ri) - step(20,ri);
  return float4(c);
}
