
#define shaderName vogel_disk

#include "Common.h" 

// FIXME: for some reason this is the only pointcloud which has a noticeable (and it is very long) hang before rendering

struct InputBuffer {
  int3 samples;
};

initialize() {
  in.samples = {64, 128, 1024};
//  in.pipeline._1 = { 0, 1, in.samples.y, 0};
}

frameInitialize() {
  ctrl.topology = 0;
  ctrl.vertexCount = in.samples.y;
  ctrl.instanceCount = 1;
}

vertexPointFn() {
  float rotationSpeed = 0.2;
  VertexOutPoint v;
  v.color = {1,1,1,1};
  v.point_size = 5;
  
  float t = sqrt((float(vid) + 0.5) / ctrl.vertexCount) ;
  float r = tau * ( 1 - 1/goldenRatio) * vid + uni.iTime * rotationSpeed;
  float2 p = (float2(t,0) * rot2d(r)) / (1.1 * uni.iResolution / uni.iResolution.y) ;
  v.where.zw = {0, 1};
  v.where.xy = p;
  return v;
}

fragmentPointFn() {
  float2 h = pointCoord;
  if ( distance(h, 0.5) > 0.5 ) {
    // fragColor.rgb = {1,0,0};
    discard_fragment();
  }
  return thisVertex.color;
}
