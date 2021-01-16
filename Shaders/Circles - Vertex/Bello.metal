
#define shaderName Bello

#include "Common.h"

struct InputBuffer {
  struct {
    int4 _1;
    int4 _2;
    int4 _3;
  } pipeline;
};

initialize() {
  in.pipeline._1 = {3, 600, 1, 0};
  in.pipeline._2 = {3, 600, 1, 0};
  in.pipeline._3 = {3, 600, 1, 0};
}

vertexPass(_1) {
  VertexOut v;

  float x = uni.iTime / 3;
  v.color = float4(float3(min(abs(cos(x)),abs(sin(2*x)))), 1);
  float radius = 0.49 * max(0.4, abs(sin(uni.iTime * 1.33)));

  v.where.xy = annulus(vid, in.pipeline._1.y / 6, radius - 0.05, radius );
  v.where.zw = {0, 1};
  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  return v;
}

vertexPass(_2) {
  // float cc = min(abs(cos(uni.iTime * 0.33)),abs(sin(uni.iTime * 0.66)));
  float3 rv = float3(0.);
  rv.x = max(0.4, abs(sin(uni.iTime * 1.33)));
  rv.y = mix(0.05, rv.x * 0.6, abs(cos(uni.iTime * 0.66)));
  rv.z = mix(rv.y * 1.2, rv.x * 0.9, abs(sin(uni.iTime) * cos(uni.iTime)));
  rv *= 0.49;

  float radius = rv.z;
  VertexOut v;
  v.where.xy = annulus(vid, in.pipeline._2.y / 6, radius - 0.05, radius );
  v.where.zw = {0, 1};
  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  v.color = float4(255, 0, 231, 255) / 255.;
  return v;
}

vertexPass(_3) {
  // float cc = min(abs(cos(uni.iTime * 0.33)),abs(sin(uni.iTime * 0.66)));
  float3 rv = float3(0.);
  rv.x = max(0.4, abs(sin(uni.iTime * 1.33)));
  rv.y = mix(0.05, rv.x * 0.6, abs(cos(uni.iTime * 0.66)));
  rv.z = mix(rv.y * 1.2, rv.x * 0.9, abs(sin(uni.iTime) * cos(uni.iTime)));
  rv *= 0.49;

  float radius = rv.y;
  VertexOut v;
  v.where.xy = annulus(vid, in.pipeline._1.y / 6, radius - 0.05, radius );
  v.where.zw = {0, 1};
  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  v.color = float4(255, 0, 231, 255) / 255.;
  return v;
}

/*
fragmentFn() {
  float2 uv = thisVertex.where.xy/uni.iResolution.xy;
  float aspect = uni.iResolution.x/uni.iResolution.y;
  uv.x *= aspect;
  float3 rv = float3(0.);
  float2 center = float2(0.5 * aspect,0.5);
  rv.x = max(0.4, abs(sin(uni.iTime * 1.33)));
  rv.y = mix(0.05, rv.x * 0.6, abs(cos(uni.iTime * 0.66)));
  rv.z = mix(rv.y * 1.2, rv.x * 0.9, abs(sin(uni.iTime) * cos(uni.iTime)));
  rv *= 0.49;
  float d = distance(center, uv);
  float f = fwidth(d) * 3.;
  float c1 = smoothstep(rv.x - f, rv.x + f, d);
  float c2 = smoothstep(rv.y - f, rv.y + f, d);
  float c3 = smoothstep(rv.z - f, rv.z + f, d);
  return float4( abs(min(abs(cos(uni.iTime * 0.33)),abs(sin(uni.iTime * 0.66))) - float3(c3 < 1. ? ( c2 < 1. ? c2 : 1.0 - c3):c1)), 1);
}
*/

/*
struct InputBuffer {
  float4 clearColor;
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  // in.clearColor = (float4(78, 58, 189, 255) / 255.) ;
  // in.clearColor *= in.clearColor;
  in.clearColor = float4(24, 13, 140, 255)/255.;
  in.pipeline._1 = {3, 600, 1, 0};
}
*/


