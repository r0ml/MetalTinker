
#define shaderName circles_1

#include "Common.h"

struct InputBuffer {};
initialize() {}


static float2 even(float2 x) {
  return (mod(x, 2.0) - 0.5) * 2.0;
}

static float2 movingLayers(float2 _st, float _layers, float _speed, float timex){
  float time = timex*_speed;
  
  float2 grid = floor(fract(_st) * _layers);
  float2 splitter = fract(time) > 0.5 ? float2(1.0, 0.0) : float2(0.0, 1.0);
  
  _st += even(grid.yx) * splitter * time * 2.0;
  return fract(_st);
}

static float circle(float2 _st, float _radius){
  float2 pos = 0.5 - _st;
  return smoothstep(_radius,_radius+0.01,length(pos));
}

fragmentFn() {

//  float2 st = thisVertex.where.xy/uni.iResolution.y;
  float2 st = textureCoord * aspectRatio;

  st = movingLayers(st*2.,9.,0.15, uni.iTime);
  return float4(float3(circle(st, .3)), 1.);
}
