
#define shaderName Combinatorial_Shape_Rendering

#include "Common.h"

static float4 rect(float2 uv, float2 start, float2 size, float4 inputColor, float4 color) {
  float2 end = start + size;
  return (uv.x >= start.x && uv.y >= start.y && uv.x <= end.x && uv.y <= end.y) ? color : inputColor;
}

static float4 circle(float2 uv, float2 center, float radius, float4 inputColor, float4 color) {
  return length(uv - center) > radius ? inputColor : color;
}

static float4 pixel(float2 uv) {
  float4 result;

  float4 gray   = float4(.5,.5,.5,1.);
  float4 red    = float4(1.,0.,0.,1.);
  float4 green  = float4(0.,1.,0.,1.);
  float4 blue   = float4(0.,0.,1.,1.);
  float4 yellow = float4(1.,1.,0.,1.);

  result = float4(0.,0.,0.,0.);
  result = rect(uv, float2(.1,.1), float2(.8,.8), result, gray);
  result = circle(uv, float2(.35,.5), .1, result, red);
  result = circle(uv, float2(.45,.5), .1, result, green);
  result = circle(uv, float2(.55,.5), .1, result, blue);
  result = circle(uv, float2(.65,.5), .1, result, yellow);

  return result;
}

static float4 blur(float2 uv) {
  float blurDelta = 0.005;
  float4 result = float4(0.,0.,0.,0.);
  for(int i = -1; i < 2; i++) for(int j = -1; j < 2; j++) {
    result += pixel(uv + float2(float(i)*blurDelta, float(j)*blurDelta));
  }
  result /= 9.0;
  return result;
}

fragmentFunc() {
  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = textureCoord * nodeAspect;

  return blur(uv);
}
