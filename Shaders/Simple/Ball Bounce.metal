
#define shaderName Ball_Bounce

#include "Common.h" 

struct KBuffer {
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  kbuff.pipeline._1 = {3, 150, 1, 0};
}

vertexFn(_1) {
  float radius = 0.1;
  VertexOut v;
  float3 a = polygon(vid, 50, radius, uni.iResolution / uni.iResolution.x );
  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};
  v.color = {0.4 , 0.5, 0.6, 1};

  float2 ctr = abs(float2( mod(uni.iTime, 2 * (1 - radius) ) - (1 - radius), 0.6 * sin(uni.iTime*5.))) - 0.5 + radius / 2 ;
  v.where.xy = v.where.xy + 2 * ctr;
  return v;
}
