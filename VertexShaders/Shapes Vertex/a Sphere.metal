
#define shaderName a_Sphere

#include "Common.h"

// if I have many more parameters for a render pass, I'll need a structure
// a possible additional parameter is "render pass output".  This would be the integer that identifies which render pass texture to use
//      as the output of the render pass, which could be referenced by subsequent passes.
// also, the pipeline could include a "compute pass" -- which is inserted between the vertex shader and the fragment shader?  In this case,
//      instead of vertex count, instance count -- the parameters are the width and height of the array?

struct InputBuffer {
    int3 parallels;
    int3 meridians;
};

initialize() {
  in.parallels = {40, 10, 200};
  in.meridians = {40, 10, 200};
//  in.pipeline._1 = {3, (in.parallels.y) * in.meridians.y * 6, 1, 0};
}

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = (in.parallels.y) * in.meridians.y * 6;
}

vertexFn() {
  VertexOut v;
  uint vv = vid % 6;
  uint vid2 = vid / 6;
  uint mm = vid2 % in.meridians.y;
  uint pp = vid2 / in.meridians.y;

  float3 ww;
  float p, m , sm;
  uint ppp, mmm;

  if (pp == 0) {
    switch (vv) {
      case 0:
        ppp = 0;
        mmm = 0;
        break;
      case 1:
        ppp = 1;
        mmm = mm+1;
        break;
      case 2:
        ppp = 1;
        mmm = mm;
        break;
      case 3:
        ppp = in.parallels.y+1;
        mmm = 0;
        break;
      case 4:
        ppp = in.parallels.y ;
        mmm = mm;
        break;
      case 5:
        ppp = in.parallels.y ;
        mmm = mm+1;
        break;
    }

  } else {
    ppp = pp + (vv != 1 && vv < 4);
    mmm = mm + (vv != 4 && vv > 1);
  }
  p = PI * float(ppp) / float(in.parallels.y + 1 );
  m = TAU * float(mmm) / float(in.meridians.y);
  sm = sin(p);
  ww = float3( sm * cos(m), sm * sin(m), cos(p) );

  v.where.xy = ww.xy * 0.5;
  v.where.z = (ww.z * 0.5 + 0.5) * 0.5 + 0.25;
  v.where.w = 1;
  v.color = v.where + float4(0.5, 0.5, 0, 0);
  return v;
}

