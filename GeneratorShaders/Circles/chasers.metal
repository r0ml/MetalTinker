
#define shaderName chasers

#include "Common.h"

static float2 thingPosition(float t, float aspect) {
  float tx = t / aspect;
  float2 p = float2(sin(2.2 * tx) - cos(1.4 * tx), cos(1.3 * t) + sin(-1.9 * t));
  p.y *= 0.2;
  p.x *= 0.4;
  return p;
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2.0;
  float aspect = uni.iResolution.x / uni.iResolution.y;
  float3 cFinal = float3(0.0);
  
  float3 color1 = float3(0.9, 0.2, 0.4);
  //float3 color2 = float3(0.8, 0.3, 0.2);
  const float radius = 0.035;
  const float tailLength = 0.7;
  const float edgeWidth = 0.03;
  for (int j = 0; j < 11; j++) {
    float thisRadius = radius + sin(float(j) * 0.7 + uni.iTime * 1.2) * 0.02;
    float dMin = 1.0;
    const int iMax = 12;
    for (int i = 0; i < iMax; i++) {
      float iPct = float(i) / float(iMax);
      float segmentDistance = length(thingPosition(uni.iTime * 2.0 + float(j) * 1.5 - iPct * tailLength, aspect) - uv);
      dMin = min(dMin, segmentDistance + pow(iPct, 0.8) * (thisRadius + edgeWidth));
    }
    cFinal += 5.0 * (1.0 - smoothstep(thisRadius, thisRadius + edgeWidth, dMin)) * color1; //mix(color1, color2, mod(float(j), 2.0));
  }
  
  return float4(float3(1.0) - cFinal, 1.0);
}
