
#define shaderName dot_ring_test_3D

#include "Common.h"

struct InputBuffer {  };
initialize() {}

static float2 polarRep(float2 U, float n) {
  n = TAU/n;
  float a = atan2(U.y, U.x),
  r = length(U);
  a = mod(a+n/2.,n) - n/2.;
  U = r * float2(cos(a), sin(a));
  return .5* ( U+U - float2(1,0) );
}

static float ring(float2 uv, float n, float s, float f) {
  uv = polarRep(uv, n);
  return smoothstep(s + f, s, length(uv));
}


fragmentFn() {
  
  float2 uv = worldCoordAspectAdjusted;
  float3 col = float3(0.);
  
  uv.x += .1 * cos(uni.iTime * .2);
  uv.y += .1 * sin(uni.iTime * .2);
  
  float k = 12.;
  float n = 8.;
  for (float i = 0., s = 1. / n; i < 1.; i += s) {
    
    float t = fract(uni.iTime * .1 + i);
    float z = smoothstep(1., .1, t);
    float f = smoothstep(0., 1., t) *
    smoothstep(1., .8, t);
    
    uv = uv * rot2d(i * .15);
    col += ring(uv * z, k, .03, .0085) * f;
    
  }
  
  col *= col;
  
  return float4(col, 1.);
  
}
