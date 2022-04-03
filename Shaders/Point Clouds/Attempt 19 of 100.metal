
#define shaderName Attempt_19_of_100

#include "Common.h"

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
  
  float3 velocity;
  float3 waviness;
};

initialize() {
  in.pipeline._1 = {0, 33, 18, 0};
  in.velocity = {2, 5, 10};
  in.waviness = { 0.005, 0.01, 0.03 };
}

vertexPointPass(_1) {
  VertexOutPoint v;
  v.point_size = 16; // this is a pixel value, so needs to be adjusted for whether
                     // it is a retina display (static) or not


  //  float2 st = thisVertex.where.xy/uni.iResolution;
  //  float2 frequency = float2(33.0, 18.0);
  float2 frequency = float2(in.pipeline._1.yz);

  float2 index = float2(vid, iid) / (frequency - 1); // floor(frequency * st)/frequency;
  float centerDist = 1.0-length(index-0.5 * (sin(uni.iTime)+1.));

  float angle = uni.iTime * in.velocity.y + centerDist * TAU;

  float2 nearest = index + in.waviness.y * float2( cos( angle ), sin( angle ) );
  v.where.xy = 2 * nearest.xy - 1;
//  v.where.xy -= float2(in.pipeline._1.yz) / uni.iResolution;
  v.where.zw = { 0, 1};
  v.color = float4( centerDist * float3(sin(uni.iTime/5.0)+0.2, .4*cos(uni.iTime/5.0+2.0)+0.2, .5*cos(uni.iTime+2.0)+0.4), 1);
  return v;
}

// the canonical "make it a circle"
fragmentPointPass(_1) {
  float2 h = pointCoord;
  if ( distance(h, 0.5) > 0.5) {
    // fragColor.rgb = {1,0,0};
    discard_fragment();
  }
  return float4(thisVertex.color.rgb, 1);
}
