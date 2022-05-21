
#define shaderName basic_2d_metaballs

#include "Common.h" 

static float3 Sphere(float2 uv, float2 position, float radius)
{
  float dist = radius / distance(uv, position);
  return float3(dist * dist);
}

fragmentFunc() {
  float2 uv = worldCoordAdjusted;
  float t = scn_frame.time;

  float3 pixel = float3(0.0, 0.0, 0.0);
  
  float2 positions[4];
  positions[0] = float2(sin(t * 1.4) * 1.3, cos(t * 2.3) * 0.4);
  positions[1] = float2(sin(t * 3.0) * 0.5, cos(t * 1.3) * 0.6);
  positions[2] = float2(sin(t * 2.1) * 0.1, cos(t * 1.9) * 0.8);
  positions[3] = float2(sin(t * 1.1) * 1.1, cos(t * 2.6) * 0.7);
  
  for	(int i = 0; i < 4; i++)
    pixel += Sphere(uv, positions[i], 0.22);
  
  pixel = step(1.0, pixel) * pixel;
  
  return float4(pixel, 1.0);
}
