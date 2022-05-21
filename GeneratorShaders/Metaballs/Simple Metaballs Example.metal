
#define shaderName simple_metaballs_example

#include "Common.h" 

static float smoothstepQuintic(float a, float b, float x) {
  x = saturate((x - a)/(b - a));
  return x*x*x*(x*(x*6.0 - 15.0) + 10.0);
}

fragmentFunc() {
  float radius = 0.3;
  //  float2 center = float2(0.5);
  float2 uv = worldCoordAdjusted / 2;
  float t = scn_frame.time;
  // float len = length(uv);
  
  float size = 0.1;
  float speed = 1.8;
  float2 p = uv+float2(cos(t*speed)*radius, sin(t*speed)*radius);
  float metaballs = smoothstep(size, 0.0, length(p));
  
  size = 0.14;
  speed = 1.2;
  p = uv+float2(cos(t*speed)*radius, sin(t*speed)*radius);
  metaballs += smoothstep(size, 0.0, length(p));
  
  size = 0.06;
  speed = 0.6;
  p = uv+float2(cos(t*speed)*radius, sin(t*speed)*radius);
  metaballs += smoothstep(size, 0.0, length(p));
  
  size = 0.12;
  speed = 1.4;
  p = uv+float2(cos(t*speed)*radius, sin(t*speed)*radius);
  metaballs += smoothstep(size, 0.0, length(p));
  
  size = 0.08;
  speed = 2.4;
  p = uv+float2(cos(t*speed)*radius, sin(t*speed)*radius);
  metaballs += smoothstep(size, 0.0, length(p));
  
  size = 0.1;
  speed = 3.0;
  p = uv+float2(cos(t*speed)*radius, sin(t*speed)*radius);
  metaballs += smoothstep(size, 0.0, length(p));
  
  return float4(smoothstepQuintic(0.9, 1.0, metaballs/0.5));
}
