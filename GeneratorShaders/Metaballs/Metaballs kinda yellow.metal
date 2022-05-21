
#define shaderName metaballs_kinda_yellow

#include "Common.h" 

static float circle(float2 uv, float2 pos, float r){
  
  return r/distance(uv, pos);
}

fragmentFunc() {
  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = textureCoord;
  uv -= .5;
  
  float r = .035;
  
  uv *= nodeAspect;

  float t = scn_frame.time;
  float c = circle(uv, float2(sin(t * 2.) * .4,  cos(t * .4) * .4), r);
  c += circle(uv, float2(sin(t * .5) * .4, cos(t * .7) * .4), r);
  c += circle(uv, float2(sin(t * .7) * .4, cos(t * .8) * .4), r);
  c += circle(uv, float2(sin(t * .2) * .4, cos(t * .3) * .4), r);
  c += circle(uv, float2(sin(t * .3) * .4, cos(t * .4) * .4), r);
  c += circle(uv, float2(sin(t * .6) * .4, cos(t) * .4), r);
  c += circle(uv, float2(sin(t * .5) * .4, cos(t * .2) * .4), r);
  c += circle(uv, float2(sin(t * .3) * .4, cos(t) * .7), r);
  
  return float4(float3(0.), 1.) + float4(1., 1. * c / 3., 0., 1.) * c;
}
