
#define shaderName a_Cylinder

#include "Common.h"

// if I have many more parameters for a render pass, I'll need a structure
// a possible additional parameter is "render pass output".  This would be the integer that identifies which render pass texture to use
//      as the output of the render pass, which could be referenced by subsequent passes.
// also, the pipeline could include a "compute pass" -- which is inserted between the vertex shader and the fragment shader?  In this case,
//      instead of vertex count, instance count -- the parameters are the width and height of the array?

struct InputBuffer {
    int3 wedges;
};

initialize() {
  in.wedges = {10, 30, 50};
//  in.pipeline._1 = {3, in.wedges.y * 12, 1, 0};
}

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = in.wedges.y * 12;
}

vertexFn() {
  VertexOut v;
  uint vv = vid % 12;
  uint vid2 = vid / 12;

  uint wedges = in.wedges.y;

  float3 ww;

  float radius = 0.5;
  float height = 0.25;
  float angle;
  float2 j;

  switch (vv) {
      case 0:
        ww = float3(0, 0, height);
        break;
      case 1:
        angle = TAU * float(vid2) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, height);
        break;
      case 2:
        angle = TAU * float(vid2+1) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, height);
        break;
      case 3:
        ww = float3(0, 0, -height);
        break;
      case 4:
        angle = TAU * float(vid2) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, -height);
        break;
      case 5:
        angle = TAU * float(vid2+1) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, -height);
        break;

      case 6:
        angle = TAU * float(vid2) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, height);
        break;
      case 7:
        angle = TAU * float(vid2) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, -height);
        break;
      case 8:
        angle = TAU * float(vid2+1) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, height);
        break;

      case 9:
        angle = TAU * float(vid2+1) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, height);
        break;
      case 10:
        angle = TAU * float(vid2) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, -height);
        break;
      case 11:
        angle = TAU * float(vid2+1) / wedges;
        j = radius * float2(sin(angle), cos(angle)) ;
        ww = float3(j, -height);
        break;
  }

  v.where.xy = ww.xy * 0.5;
  v.where.z = ww.z * 0.5 + 1;
  v.where.w = 1;
  v.color = v.where + float4(0.5, 0.5, 0, 0);
  return v;
}

