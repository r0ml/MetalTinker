
#define shaderName infinite_sierpinski

#include "Common.h" 

static bool get(float2 uv, float2 o, constant Uniform &uni, texture2d<float> ri) {
  uv += o / uni.iResolution;
  return ri.sample(iChannel0, uv).x > 0.5 && uv.x >= 0. && uv.x < 1.;
}

fragmentFn(texture2d<float> lastFrame) {

  float2 winCoord = thisVertex.where.xy;
  float2 x = winCoord / uni.iResolution;
  
  int v = int(dot(float3(
                         get(x, float2(-1, 0), uni, lastFrame),
                         get(x, float2(0, 0), uni,  lastFrame),
                         get(x, float2(1, 0), uni,  lastFrame)
                         ), float3(1)));
  
  return float4(uni.iTime < .1 ? abs(uni.iResolution.x / 2. - thisVertex.where.x - .5) < 1. :
                x.y < 1. / uni.iResolution.y ? (v == 0 || v == 3) :
                get(x, float2(0, -1), uni, lastFrame));
}
