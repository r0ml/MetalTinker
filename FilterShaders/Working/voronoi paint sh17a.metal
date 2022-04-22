
#define shaderName voronoi_paint_sh17a

#include "Common.h"
struct KBuffer {
};
initialize() {}


fragmentFn1() {
  FragmentOutput f;
  f.fragColor = texelFetch(renderInput[0], int2(thisVertex.where.xy),0);

// ============================================== buffers =============================

  //setting the previous frame pixel color to f
  f.pass1 = texelFetch(renderInput[0], int2(thisVertex.where.xy),0);
  
  float o = 1e4-length(uni.iMouse.xy * uni.iResolution.xy -thisVertex.where.xy);
  //f.a is the length to closest voronoi cell center, and o is
  if (f.pass1.a < o && uni.mouseButtons > 0) {
    //changes f, rgb is the random color, and a is the distance to the closest voronoi cell center
    f.pass1 = float4(fract(sin(uni.iTime*float3(1,2,3))*9.)-step(1e4-o,10.),o);
  }
  return f;
}
