
#define shaderName Bello2

#include "Common.h"

fragmentFunc() {
  float t = scn_frame.time;
//  float2 uv = thisVertex.where.xy/uni.iResolution.xy;
//  float aspect = uni.iResolution.x/uni.iResolution.y;
//  uv.x *= aspect;
  float2 uv = textureCoord * nodeAspect;
  float3 rv = float3(0.);
  float2 center = 0.5 * nodeAspect;
  rv.x = max(0.4, abs(sin(t * 1.33)));
  rv.y = mix(0.05, rv.x * 0.6, abs(cos(t * 0.66)));
  rv.z = mix(rv.y * 1.2, rv.x * 0.9, abs(sin(t) * cos(t)));
  rv *= 0.49;
  float d = distance(center, uv);
  float f = fwidth(d) * 3.;
  float c1 = smoothstep(rv.x - f, rv.x + f, d);
  float c2 = smoothstep(rv.y - f, rv.y + f, d);
  float c3 = smoothstep(rv.z - f, rv.z + f, d);
  return float4( abs(min(abs(cos(t * 0.33)),abs(sin(t * 0.66))) - float3(c3 < 1. ? ( c2 < 1. ? c2 : 1.0 - c3):c1)), 1);
}

