
#define shaderName Bokehlicious

#include "Common.h"

struct InputBuffer {
};
initialize() {
}

constant const int NUM_PARTICLES = 128;

static float bokeh(float2 p, float2 a, float r, texture2d<float> tex)
{
  float l = length(p - a);
  
  if (l > r + 0.1)
  {
    return 0.0;
  }
  
  float s = 0.01;
  float d = l * exp(sin(9.0 * atan2(p.y - a.y, p.x - a.x)) * 0.02);
  float g = mix(0.9, 0.6, tex.sample(iChannel0, 4.0 * p - a * 1.9).x);
  float t = smoothstep(r + s, r - s, d);
  
  return 0.001 * mix(0.0, mix(g, t, saturate(l / r)), t) / (r * r);
}

fragmentFn(texture2d<float> tex0) {
  float aperture = 0.5;
  float focus = 3.5;
  
  if (uni.mouseButtons) {
    aperture = uni.iMouse.x ;
    focus = 7.0 * uni.iMouse.y ;
  }
  
  float2 uv = worldCoordAspectAdjusted / 2.;
  float3 c = float3(0);
  
  for (int i = 0; i < NUM_PARTICLES; i++)
  {
    float3 color;
    float3 pos;
    float radius;
    
    float t = float(i) / float(NUM_PARTICLES);
    float p = t + uni.iTime * 0.03;
    color = normalize(float3(sin(t * TAU * 1.0) + 5.1, cos(t * TAU * 2.0) + 1.1, cos(t * TAU * 3.0) + 1.1));
    pos = float3(2.0 * sin(t * TAU * 5.0 + p * 0.7),
                 abs(sin(p * 3.0 * TAU)) - 0.5,
                 4.0 * cos(t * TAU + p * 0.8));
    float d = pos.z + 2.5;
    
    if (d > 0.0)
    {
      pos.xy /= d;
      radius = max(abs(1.0 / d - 1.0 / focus) * aperture, 0.0001);
      c += color * bokeh(uv, pos.xy, radius, tex0);
    }
  }
  
  c = gammaEncode(c);
  return float4(c, 1.0);
}
