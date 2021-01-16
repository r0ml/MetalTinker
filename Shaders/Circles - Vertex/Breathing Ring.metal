
#define shaderName Breathing_Ring

#include "Common.h" 

struct InputBuffer {
  float4 clearColor;
  bool monotonic = false;
  float3 thickness;
  bool fade;
  struct {
    int4 _1;
  } pipeline;
};

initialize() {
  in.clearColor = float4(24, 13, 140, 255)/255.;
  in.pipeline._1 = {3, 600, 1, 0};
  in.thickness = { 0.01, 0.03, 0.1};
}

vertexPass(_1) {
  float thickness = in.thickness.y;
  
  float radius = in.monotonic ? thickness + 0.4 * fract(uni.iTime / 3.0) : 0.25 + thickness + 0.25 * sin(uni.iTime);
  
  VertexOut v;
  v.where.xy = annulus(vid, in.pipeline._1.y / 6, radius - thickness, radius );
  v.where.zw = {0, 1};
  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  v.color = float4(255, 0, 231, 255) / 255.;

  if (in.fade) {
    if (mod(vid,6) == 0 || mod(vid,6) == 4 || mod(vid, 6) == 5)  {
      float ft = fract(uni.iTime / 3);
      v.color = (1 - ft) * float4(0.4, 0.7, 0.9, 1.0);
    } else {
      v.color = 0;
    }
  }
  return v;
}
