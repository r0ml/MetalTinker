
#define shaderName infinityparticles

#include "Common.h" 

struct InputBuffer {
  float4 clearColor = 0;
  struct {
    int4 _1;
  } pipeline;
};

initialize() {
  in.pipeline._1 = {0, 1, 500, 0} ;
}

static float2 dotCoordinates (float radius, float2 offset, float t) {
  float2 pos = float2(cos(t), cos(t) * sin(t));
  return 2 * (offset + radius * pos) - 1;
}

vertexPointPass(_1) {
  VertexOutPoint v;
  v.where.z = 0;
  v.where.w = 1;
  v.color = {0.5, 0.7, 0, 0.4};
  v.point_size = 30;
  
  int xid = in.pipeline._1.z - iid;
  
  v.where.xy = dotCoordinates( sign( (xid % 2)-0.5 ) * 0.45, float2(0.5, 0.5), uni.iTime-(0.02 * xid / 2.0));
  float fade = (float(xid) / float(in.pipeline._1.z));
  v.color = saturate(float4( 0.5 * (v.where.xy + 1), 0.8 + 0.2 * sin(uni.iTime), 1) - fade);
  return v;
}

fragmentPointPass(_1) {
  float2 h = pointCoord;
  if ( distance(h, 0.5) > 0.5) {
    discard_fragment();
  }
  return float4(thisVertex.color.rgb, 1);
}
