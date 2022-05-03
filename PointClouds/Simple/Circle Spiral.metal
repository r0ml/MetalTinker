
#define shaderName Circle_Spiral

#include "Common.h"

//  float4 clearColor = {0,0.2,0.3,0.5};

frameInitialize() {
  ctrl.vertexCount  = 1;
  ctrl.instanceCount = 16 * 4 - 1;
  ctrl.topology = 0;
//  in.pipeline._1 = {0, 1, 16 * 4 - 1, 0};
}

vertexPointFn() {
  VertexOutPoint v;
  v.color = {0.5, 0.7, 0, 0.4};
  v.point_size = 5;
  v.where.z = 0;
  v.where.w = 1;

  float circleN = float(iid) / ctrl.instanceCount;
  float t = fract( circleN + uni.iTime * 0.2 );
  
  float offset = 0.35 + 0.65 * t;
  float angle  = fract( float(iid) / 16.0 + uni.iTime * 0.01 + circleN / 8.0 );
  float radius = mix( 50.0, 0.0, 1.0 - saturate( 1.2 * ( 1.0 - abs( 2.0 * t - 1.0 ) ) ) );
  
  float2 p2 = float2(offset, 0);
  p2 *= rot2d( -angle * TAU );
  v.where.xy = p2 / (uni.iResolution / uni.iResolution.y);
  v.point_size = radius;
  return v;
}

fragmentPointFn() {
  float2 h = pointCoord;
  if ( distance(h, 0.5) > 0.5) {
    discard_fragment();
  }
  return thisVertex.color;
}
