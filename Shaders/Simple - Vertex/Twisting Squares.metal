
#define shaderName Twisting_Squares

#include "Common.h"

static constant uint instances = 18;

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  in.pipeline._1 = {3, 6, instances, 0}; // 20 instances of a square
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

static float smootheststep(float edge0, float edge1, float x) {
  x = saturate((x - edge0)/(edge1 - edge0))  * PI;
  return 0.5 - (cos(x) * 0.5);
}

vertexPass(_1) {
  VertexOut v;
  v.color = float4(0.7, 0.8, 0.9, 1);
  v.where.z = 0;
  v.where.w = 1;
  
  v.where.xy = square_triangles[vid];
  
  float period = 2.0;
  float time = uni.iTime / period;
  time = mod(time, 1.0);
  time = smootheststep(0.0, 1.0, time);
  
  float rotateAmount = (iid * 0.25 + 0.25) * TAU;
  float size = 0.4 * ( (float(iid) + 1) / instances );
  v.color = mix(0., 1., iid % 2);
  
  v.where.xy = (v.where.xy - 0.5 ) * size * rot2d( - rotateAmount * time);
  
  v.where.xy = 2 * v.where.xy;
  v.where.y *= uni.iResolution.x / uni.iResolution.y; // aspect ratio
  
  return v;
}
