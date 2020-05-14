
#define shaderName Breathing_Ring

#include "Common.h" 

struct KBuffer {
  float4 clearColor;
  struct {
    bool monotonic = false;
    float3 thickness;
  } options;
  struct {
    int4 _1;
  } pipeline;
};

initialize() {
  kbuff.clearColor = float4(24, 13, 140, 255)/255.;
  kbuff.pipeline._1 = {3, 600, 1, 0};
  kbuff.options.thickness = { 0.01, 0.03, 0.05};
}

vertexFn(_1) {
  float thickness = kbuff.options.thickness.y;

  float radius = kbuff.options.monotonic ? thickness + 0.4 * fract(uni.iTime / 3.0)
  : 0.25 + 0.025 + 0.25 * sin(uni.iTime);

  VertexOut v;
  float3 a = annulus(vid, 200, radius - thickness, radius, uni.iResolution / uni.iResolution.x );
  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};

  v.color = float4(255, 0, 231, 255) / 255.;
  return v;
}
