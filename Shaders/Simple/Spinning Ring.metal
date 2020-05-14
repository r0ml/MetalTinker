
#define shaderName Spinning_Ring

#include "Common.h" 

constant const int ringSides = 200;

struct KBuffer {
  float4 clearColor = 0;
  struct {
    int4 _1;
  } pipeline;
  struct {
    float3 radius;
    float3 thickness;
  } options;
};
initialize() {
  kbuff.pipeline._1 = {3, 3 * ringSides, 1, 0};
  kbuff.options.thickness = { 0.01, 0.05, 0.1};
  kbuff.options.radius = {0.2, 0.3, 0.5};
}

/*

struct MyVertexOut {
  float4  where [[position]];   // this is in the range -1 -> 1 in the vertex shader,  0 -> viewSize in the fragment shader
  float4  color;
  float4  barrio;               // this is in the range 0 -> 1 in the vertex shader
  float theta;
};
*/

// #undef VertexOut
// #define VertexOut MyVertexOut

vertexFn(_1) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.y;
  float3 a = annulus(vid, ringSides, kbuff.options.radius.y - kbuff.options.thickness.y / 2, kbuff.options.radius.y + kbuff.options.thickness.y / 2, aspect);
  
  a.xy = (a.xy * aspect * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.))) / aspect;
  
  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};
  v.color = smoothstep(1, 0, a.z * 1.05);
//  v.theta = a.z;
  return v;
}
