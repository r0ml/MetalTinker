
#define shaderName dot_wave

#include "Common.h" 

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
};

initialize() {
  in.pipeline._1 = {0, 60, 30, 0};
}

vertexPointPass(_1) {
  VertexOutPoint v;
  v.point_size = 12;

  float2 b = (-0.5 + float2(vid, iid)) / float2(in.pipeline._1.yz - 2) ;

  // fragmentFn() {
  //  float2 U = 20.* ( thisVertex.where.xy+thisVertex.where.xy - uni.iResolution.xy ) / uni.iResolution.y;


  float2 oo = cos(.3 * float2(vid, in.pipeline._1.z - iid) - uni.iTime) / float2(in.pipeline._1.yz);
  float r = 30 * oo.x * oo.y;

  b += r;

  //  float2 oo  = cos(.3*U - uni.iTime);   // -4 by coyote
  //  return .1/length( fract( U -2.*oo.x*oo.y )-.5 );

  v.where.xy = 2 * b - 1;
  v.where.zw = {0, 1};

  v.color = 1;
  // O += .1/length( fract( U - 2.*length(O.xy) )-.5 ) -O;
  return v;
}

// the cananical "make it a circle"
fragmentPointPass(_1) {
  float2 h = pointCoord;
  if ( distance(h, 0.5) > 0.5) {
    // fragColor.rgb = {1,0,0};
    discard_fragment();
  }
  return float4(thisVertex.color.rgb, 1);
}
