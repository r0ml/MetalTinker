
#define shaderName a_Torus

#include "Common.h"

// if I have many more parameters for a render pass, I'll need a structure
// a possible additional parameter is "render pass output".  This would be the integer that identifies which render pass texture to use
//      as the output of the render pass, which could be referenced by subsequent passes.
// also, the pipeline could include a "compute pass" -- which is inserted between the vertex shader and the fragment shader?  In this case,
//      instead of vertex count, instance count -- the parameters are the width and height of the array?

struct InputBuffer {
    int3 wedges;
    int3 stripes;
    float3 outerRadius;
    float3 innerRadius;
};

initialize() {
  in.wedges = {10, 30, 50};
  in.stripes = {10, 30, 50};
  in.outerRadius = {0.3, 0.6, 1.0};
  in.innerRadius = {0.05, 0.15, 0.3};
//  in.pipeline._1 = {3, in.wedges.y * in.stripes.y * 6, 1, 0};
}

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = in.wedges.y * in.stripes.y * 6;
//  in.pipeline._1.y = in.wedges.y * in.stripes.y * 6;
}

vertexFn() {
  VertexOut v;
  uint vv = vid % 6;
  uint vid2 = vid / 6;
  uint vid3 = vid2 % in.wedges.y; // wedge
  uint vid4 = vid2 / in.wedges.y; // stripe


  uint wedges = in.wedges.y;
  uint stripes = in.stripes.y;

  float oradius = in.outerRadius.y;
  float iradius = in.innerRadius.y;

  float angle1 = TAU * float(vid3 + (vv != 4 && vv > 1) ) / float(wedges);
  float angle2 = TAU * float(vid4 + (vv == 1 || vv > 3) ) / float(stripes);

  float3 c = float3(oradius, 0, 0);
  float3 p = float3(oradius-iradius, 0, 0);
  p = c + (p - c)* rotY(angle2);
  p = p * rotZ(angle1);

  v.where.xy = p.xy * 0.5;
  v.where.z = p.z * 0.5 + 1;
  v.where.w = 1;
  v.color = v.where + float4(0.5, 0.5, 0.5, 0);
  return v;
}

