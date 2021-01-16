
#define shaderName vogel_disk

#include "Common.h" 

struct InputBuffer {
  int3 samples;
  struct {
    int4 _1;
  } pipeline;
};

// the problem here is that updating the number of samples will not modify the pipeline vertex size
// because initialize only gets called once when the shader launches.
// I need a way to have the CPU side pick up the results of a frame initialization pass and use it to create the
// rencder encoders.
// I would prefer not to have the pipeline wait for the frame initialization to run before proceeding.
// That suggests that the pipeline should have a compute shader which runs during the pipeline which updates the in
// parameters for the next frame.
initialize() {
  in.samples = {64, 128, 1024};
  in.pipeline._1 = { 0, 1, in.samples.y, 0};
}

vertexPointPass(_1) {
  float rotationSpeed = 0.2;
  VertexOutPoint v;
  v.color = {1,1,1,1};
  v.point_size = 5;
  
  float t = sqrt((float(iid) + 0.5) / in.pipeline._1.z) ;
  float r = tau * ( 1 - 1/goldenRatio) * iid + uni.iTime * rotationSpeed;
  float2 p = (float2(t,0) * rot2d(r)) / (1.1 * uni.iResolution / uni.iResolution.y) ;
  v.where.zw = {0, 1};
  v.where.xy = p;
  return v;
}

fragmentPointPass(_1) {
  float2 h = pointCoord;
  if ( distance(h, 0.5) > 0.5 ) {
    // fragColor.rgb = {1,0,0};
    discard_fragment();
  }
  return thisVertex.color;
}
