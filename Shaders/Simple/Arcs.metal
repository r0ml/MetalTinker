
#define shaderName Arcs

#include "Common.h"

constant const int arcSides = 25;

struct KBuffer {
  float4 clearColor = 0;
  struct {
    int4 _1;
    int4 _2;
    int4 _3;
  } pipeline;
  struct {
    float3 radius;
    float3 thickness;
  } options;
};

initialize() {
  kbuff.pipeline._1 = {3, 3 * arcSides, 1, 1};
  kbuff.pipeline._2 = {3, 3 * arcSides, 1, 1};
  kbuff.pipeline._3 = {3, 3 * arcSides, 1, 1};

  kbuff.clearColor = {0, 0, 0, 1};
  kbuff.options.thickness = { 0.01, 0.05, 0.1};
  kbuff.options.radius = {0.2, 0.3, 0.5};
}

vertexFn(_1) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.y;
  float3 a = annulus(vid, arcSides, kbuff.options.radius.y - kbuff.options.thickness.y / 2, kbuff.options.radius.y + kbuff.options.thickness.y / 2,
                     aspect, 0.01, PI/4-0.01);

//  a.xy = (a.xy * aspect * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.))) / aspect;

  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};
  v.color = {0.5, 0.5, 0.5, 1};
  return v;
}


vertexFn(_2) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.y;
  float3 a = annulus(vid, arcSides, kbuff.options.radius.y - kbuff.options.thickness.y / 2, kbuff.options.radius.y + kbuff.options.thickness.y / 2,
                     aspect, 0.01+PI/4, PI/2-0.01);

//  a.xy = (a.xy * aspect * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.))) / aspect;

  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};
  v.color = {0.7, 0.5, 0.5, 1 };
  return v;
}

vertexFn(_3) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.y;
  float3 a = annulus(vid, arcSides, kbuff.options.radius.y - kbuff.options.thickness.y / 2, kbuff.options.radius.y + kbuff.options.thickness.y / 2,
                     aspect, 0.01+PI/2, 3 * PI/4-0.01);

//  a.xy = (a.xy * aspect * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.))) / aspect;

  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};
  v.color = {0.5, 0.5, 0.7, 1 };
  return v;
}
