
#define shaderName Animated_Pinwheel

#include "Common.h"

constant float4 color1 = float4(1, 1, 1, 1);
constant float4 color2 = float4(0, 0, 0, 1);
constant float speed = 2.0;

struct KBuffer {
  struct {
    int3 spokes = { 6, 12, 20};
  } options;
  int vertexCount;
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  kbuff.pipeline._1 = { 3, 3 * kbuff.options.spokes.y, 1, 0 } ; // topology, vertexCount, instanceCount
}
 
vertexFn(_1) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.x;
  
  int p = vid % 3; // 0, 1, or 2 vertex
  int q = vid / 3;
  float angle = tau / float(kbuff.options.spokes.y);
  float ar = fmod(uni.iTime / speed, tau);

  switch(p) {
    case 0:
      v.barrio = 0.5;
      break;
    case 1:
      v.barrio.xy = 0.5 + (float2(2., 0) * aspect * rot2d( ar + float(q) * angle )) / aspect;
      break;
    case 2:
      v.barrio.xy = 0.5 + (float2(2., 0) * aspect * rot2d( ar + float(q+1) * angle )) / aspect;
      break;
  }
  v.barrio.zw = 0;
  
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5 ;
  v.where.zw = {0, 1};

  v.color =  (q % 2) ? color1 : color2;
  return v;
}
