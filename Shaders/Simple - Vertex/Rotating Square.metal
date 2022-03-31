
#define shaderName Rotating_Square

#include "Common.h" 

struct InputBuffer {
  struct {
    int revolve;
    int rotate;
  } variant;
  struct {
    int3 _1;
  } pipeline;
};

initialize() {
  in.variant.revolve = 1;
  in.pipeline._1 = { 4, 4, 1 };
}

// this then is the vertex shader ?
vertexPass(_1) {
  VertexOut v;
  v.color = float4(0.7, 0.8, 0.9, 1);
  v.where.z = 0;
  v.where.w = 1;
  
  v.where.x = 2 * step( float(vid), 1) - 1;
  v.where.y = 1-2*fmod(float(vid), 2);
  
  
  
  if (in.variant.revolve) {
    v.where.xy *= 0.1;
    float2 translate = float2(-cos(uni.iTime),sin(uni.iTime));
    v.where.xy += translate * 0.45;
  } else {
    v.where.xy *= 0.15;
    v.where.xy = v.where.xy * rot2d( - TAU / 4 * fmod(uni.iTime, 4));
  }
  v.where.y *= uni.iResolution.x / uni.iResolution.y; // aspect ratio
  
//  if (uni.mouseButtons) {
    v.where.xy += 2 * uni.iMouse.xy - 1;
//  }
  
  return v;
}
