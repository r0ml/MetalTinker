
#define shaderName Basic_Bar

#include "Common.h" 

struct InputBuffer {
//  float4 clearColor;
  struct {
    int3 _1;
  } pipeline;
};
initialize() {
//  in.clearColor = {1,1,1,0.1};
  in.pipeline._1 = {3, 6, 2};
}

static constant float2 square_triangles[6] = {
  // front face
  { 0, 1 },     // Front-top-left
  { 1, 1 },      // Front-top-right
  { 0, 0 },    // Front-bottom-left
  
  { 1, 1 },
  { 0, 0 },
  { 1, 0 }     // Front-bottom-right
};

vertexPass(_1) {
  VertexOut v;
  v.color = 0;
  v.color.w = 1;
  v.where.z = 0;
  v.where.w = 1;
  
  float2 bar = (2 * uni.iMouse.xy - 1) * float2(1, -1);
  float aspect = uni.iResolution.x / uni.iResolution.y;
  
  v.where.xy = 2 * square_triangles[vid] - 1;
  float2 bars[2] = { float2(1, 0.01 * aspect), float2(0.01, 1) };
  float2 offset[2] = { float2(0, bar.y), float2(bar.x, 0)} ;

  v.where.xy *= bars[iid];
  v.where.xy += offset[iid];

  return v;
}
