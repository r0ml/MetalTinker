
#define shaderName a_Cube_5

#include "Common.h"
struct InputBuffer {  };
initialize() {}

constant const int STEPS = 64;
constant const float EPS = 0.01;
constant const float FAR = 10.0;

// Function of distance.
static float map( float3 p, float time ) {
  p += float3(0,-1,0);
  p.xz = p.xz * rot2d(time);
  return sdBox(p,float3(1.1));
}

// Gradient (numeric) function of the distance function.
static float3 grad(float3 p, float time) {
  float2 q = float2(0.0, EPS);
  
  return float3(map(p + q.yxx, time) - map(p - q.yxx, time),
                map(p + q.xyx, time) - map(p - q.xyx, time),
                map(p + q.xxy, time) - map(p - q.xxy, time));
}

static float3 shade(float3 ro, float3 rd, float t, float time) {
  float3 n = normalize(grad(ro + t*rd, time));
  return float3(0.3, 0.8, 0.7)*pow(1.0-dot(-rd, n), 1.5);
}



fragmentFn() {
  // Prepare the radius.
  float2 uv = worldCoordAspectAdjusted;
  
  
  
  float3 ro = float3(0.0, 1.0, 3.0); // start of the radius.
  float3 rd = normalize(float3(uv, -1.0)); // direction of the radius.
  
  // Loop do raymarcher.
  float t = 0.0, d = EPS;
  for (int i = 0; i < STEPS; ++i) {
    d = map(ro + t*rd, uni.iTime);
    if (d < EPS || t > FAR) break;
    t += d;
  }
  
  // Shading.
  float3 col = d < EPS ? shade(ro, rd, t, uni.iTime) : float3(0.3, 0.6, 0.7)*(2.0-length(uv));
  
  // Post-processing.
  col = smoothstep(0.0, 1.0, col);
  col = pow(col, float3(0.45));
  
  return float4(col,1.0);
}
