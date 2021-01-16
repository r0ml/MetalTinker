
#define shaderName vogels_distrib

#include "Common.h" 

struct InputBuffer {
  float4 clearColor = {0,0,0,0};
  struct {
    int4 _1;
  } pipeline;
};

initialize() {
  in.pipeline._1 = {0, 1, 2000, 0};
}

vertexPointPass(_1) {
  VertexOutPoint v;
  v.color = {1,1,1,1};
  v.point_size = uni.iResolution.y / 40;
  
  float t = sqrt(float(iid) / (in.pipeline._1.z / 2.2) );
  float r = tau * ( 1 - 1/goldenRatio);
  float2 p = float2(t,0) * rot2d(r * float(iid));
  v.where.zw = {0, 1};
  v.where.xy = p;
  return v;
}

fragmentPointPass(_1) {
  float2 h = pointCoord;
  if ( distance(h, 0.5) > 0.5 || distance(h, 0.5) < 0.35) {
    // fragColor.rgb = {1,0,0};
    discard_fragment();
  }
  return float4(thisVertex.color.rgb, 1);
}
