
#define shaderName Animated_Pinwheel

#include "Common.h"

constant float4 color1 = float4(1, 1, 1, 1);
constant float4 color2 = float4(0, 0, 0, 1);
constant float speed = 2.0;

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
  int3 spokes;
  int vertexCount;
};
initialize() {
  in.spokes = { 6, 12, 20 };
  in.pipeline._1 = { 3, 3 * in.spokes.y, 1, 0 } ; // topology, vertexCount, instanceCount
}
 
vertexPass(_1) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.x;
  
  int p = vid % 3; // 0, 1, or 2 vertex
  int q = vid / 3;
  float angle = tau / float(in.spokes.y);
  float ar = fmod(uni.iTime / speed, tau);
  float2 b = 0.5;

  switch(p) {
    case 0:
      b = 0.5;
      break;
    case 1:
      b = 0.5 + (float2(2., 0) * aspect * rot2d( ar + float(q) * angle )) / aspect;
      break;
    case 2:
      b = 0.5 + (float2(2., 0) * aspect * rot2d( ar + float(q+1) * angle )) / aspect;
      break;
  }

  v.where.xy = (2 * b - 1) * 0.5 ;
  v.where.zw = {0, 1};

  v.color =  (q % 2) ? color1 : color2;
  return v;
}
