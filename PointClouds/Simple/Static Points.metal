
#define shaderName Static_Points

#include "Common.h"


struct InputBuffer {
  float4 clearColor = {0,0,0,1}; // the clearColor needs to have alpha = 1 to show up in the preview.
};

initialize() {
  in.clearColor = {0, 0, 0, 1};
}

frameInitialize() {
  ctrl.instanceCount = 6;
  ctrl.vertexCount = 1;
  ctrl.topology = 0;
//  in.pipeline._1 = {0, 1, 6};
}

vertexPointFn() {
  VertexOutPoint v;
  
  switch(iid) {
  case 0:
    v.color = float4(1,1,1,0.4);
    v.point_size = 0.01 * 2 * uni.iResolution.y;
    v.where.xy = { -0.6, -0.2 };
    break;
  case 1:
    v.color = float4(1,1,1,1);
    v.point_size = 0.05 * 2 * uni.iResolution.y;
    v.where.xy = {0.4, -0.4 };
    break;
  case 2:
    v.color = float4(1,1,1,1);
    v.point_size = 0.001 * 2 * uni.iResolution.y;
    v.where.xy = {-0.2, -0.2 };
    break;
  case 3:
    v.color = float4(1,1,1,0.5);
    v.point_size = 0.1 * 2 * uni.iResolution.y;
    v.where.xy = { 0, -0.8 };
    break;
  case 4:
    v.color = float4(1,1,1,0.8);
    v.point_size = 0.04 * 2 * uni.iResolution.y;
    v.where.xy = { -0.4, 0.4 };
    break;
  case 5:
    v.color = float4(1,1,1,1);
    v.point_size = 0.02 * 2 * uni.iResolution.y;
    v.where.xy = {0.8, 0.8};
    break;
  }
  v.where.w = 1;
  return v;
}

fragmentPointFn() {
  float2 h = pointCoord;
  float a = 1.0 - smoothstep(0, 0.005, distance(h, 0.5)-0.5);
  return mix(in.clearColor, thisVertex.color, a );
}
