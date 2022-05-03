
#define shaderName vogels_distrib

#include "Common.h" 


frameInitialize() {
//  in.pipeline._1 = {0, 1, 2000, 0};
  ctrl.topology = 0;
  ctrl.instanceCount = 2000;
  ctrl.vertexCount = 1;
}

vertexPointFn() {
  VertexOutPoint v;
  v.color = {1,1,1,1};
  v.point_size = uni.iResolution.y / 40;
  
  float t = sqrt(float(iid) / (ctrl.instanceCount / 2.2) );
  float r = tau * ( 1 - 1/goldenRatio);
  float2 p = float2(t,0) * rot2d(r * float(iid));
  v.where.zw = {0, 1};
  v.where.xy = p;
  return v;
}

fragmentPointFn() {
  float2 h = pointCoord;
  if ( distance(h, 0.5) > 0.5 || distance(h, 0.5) < 0.35) {
    // fragColor.rgb = {1,0,0};
    discard_fragment();
  }
  return float4(thisVertex.color.rgb, 1);
}
