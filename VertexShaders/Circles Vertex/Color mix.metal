
#define shaderName Color_mix

#include "Common.h" 

constant const int vc = 150;

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = vc;
  ctrl.instanceCount = 3;
//  ctrl.blend = true
}

vertexFn() {
  float radius = 0.5;
  VertexOut v;
  v.where.xy = polygon(vid, ctrl.vertexCount / 3, radius );
  v.where.zw = {0, 1};

  v.color = {0, 0, 0, 1};
  v.color[iid] = 1;

  float2 j = -0.3 * cos(2 * (iid+1) + float2(1.6, 0) - 1);

  v.where = scale(1 / aspectRatio.x, 1 / aspectRatio.y, 1) * translation(j.x, j.y, 0) * v.where ;
  return v;
}

/*

float C(float2 U, float2 R, thread float& a) {
  return length(U/R.y -.3* cos(2.*++a +float2(1.6,0))) < .5 ;    // length(U-.3*sincos(k.2pi/3))
}

fragmentFn() {

  //#define C  1./length(U/O.y -.3* cos(2.*++O.a +float2(1.6,0))) -1. // smooth variant +3

  float2 U = thisVertex.where.xy.xy + thisVertex.where.xy.xy - uni.iResolution.xy;
  float a = 0;
  return float4(C(U, uni.iResolution.xy, a),C(U, uni.iResolution.xy, a),C(U, uni.iResolution.xy, a),1);
}
*/
