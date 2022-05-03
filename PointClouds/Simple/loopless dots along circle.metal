
#define shaderName loopless_dots_along_circle

#include "Common.h"

struct InputBuffer {
  int3 maxCircles;
  bool ellipse;
  float n;
};

initialize() {
//  in.pipeline._1 = {0, 5, 1, 0};
  in.maxCircles = {10, 30, 50};
  in.n = 1 + float(in.maxCircles.y);
//  in.pipeline._1.y = ceil(in.n);
}

frameInitialize() {
  in.n = 1 + float(in.maxCircles.y) * (0.5 + 0.5 * sin(uni.iTime));
  ctrl.vertexCount = 5;
  ctrl.instanceCount = ceil(in.n);
  ctrl.topology = 0;
}

#undef VertexOut
#define VertexOut VertexOutPoint

float4 hue(float n) {
  return .6 + .6 * cos( n + float4(0,23,21,0) );
}

// this should be the last function in the pipeline
/*computeFn() {
  in.pipeline._1.y = ceil(in.n);
}
*/

vertexPointFn() {
  VertexOutPoint v;
  v.point_size = uni.iResolution.y / 40;

  float r = .5;                                    // circle radius
  float n = in.n;

  float neg = sign( (vid % 2 == 1) - 0.5) ;

  float j = neg * float( vid / 2 + 0.5) / n * tau ;

  float2 b = 0.5 * (float2(r * cos(j), r * sin(j)) * uni.iResolution.y / uni.iResolution + 1);

  v.where.xy = 2 * b - 1;
  v.where.zw = {0, 1};

  v.color = .6 + .6 * cos( j + float4(0,23,21,0) );
  return v;
}

// the canonical "make it a circle"
  fragmentPointFn() {
    float2 h = pointCoord;
    if ( distance(h, 0.5) > 0.5) {
      // fragColor.rgb = {1,0,0};
      discard_fragment();
    }
    return thisVertex.color;
  }
