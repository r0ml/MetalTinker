
#define shaderName Basic_Orbit

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

  float3 ctr = float3(sin(uni.iTime), 0,  1 + cos(uni.iTime) ) ;
  v.where.xyz = v.where.xyz + 0.5 * ctr;
  v.barrio.z = v.where.z;
  return v;
}
