
#define shaderName Dots_On_Planes

#include "Common.h"

struct InputBuffer {  };
initialize() {}


fragmentFn() {
  float time = uni.iTime * 0.25;
  float2 uv = worldCoordAspectAdjusted;
  uv *= float2(0.35, 1.);
  
  // z-rotation
  float zRot = 0.5 * sin(time);
  uv *= float2x2(cos(zRot), sin(zRot), -sin(zRot), cos(zRot));
  
  // 3d params
  // 3d plane technique from: http://glslsandbox.com/e#37557.0
  float horizon = 0.5 * cos(time);
  float fov = 0.25 + 0.015 * sin(time);
  float scaling = 0.1;
  
  // create a 2nd uv with warped perspective
  float3 p = float3(uv.x, fov, uv.y - horizon);
  float2 s = float2(p.x/p.z, p.y/p.z) * scaling;
  
  // wobble the perspective-warped uv
  float oscFreq = 12.;
  float oscAmp = 0.03;
  float zScroll = sin(time) * 0.1; // reverses direction between top & bottom
  s += float2(zScroll, oscAmp * sin(time + s.x * oscFreq));
  
  // y-rotation
  float yRot = sin(time);
  s *= float2x2(cos(yRot), sin(yRot), -sin(yRot), cos(yRot));
  
  // normal drawing here
  // draw dot grid
  float gridSize = 50. + 2. * sin(time);
  s = fract(s * gridSize) - 0.5;
  float col = 1. - smoothstep(0.25 + 0.1 * sin(time), 0.35 + 0.1 * sin(time), length(s));
  
  // fade into distance
  col *= p.z * p.z * 5.0;
  
  return float4(float3(col),1.0);
}
