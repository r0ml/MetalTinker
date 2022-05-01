
#define shaderName two_circle

#include "Common.h" 

static float3 DrawCircle( float2 uv, float2 center, float radius, float blur, float3 backCol, float3 drawCol)
{
  float dis = length(uv - center);
  float rate = smoothstep(radius, radius - blur, dis);
  float3 col = mix(backCol, drawCol, rate);
  return col;
}

fragmentFn() {
  float3 red = float3(1.0, 0.0, 0.0);
  float3 green = float3(0.0, 1.0, 0.0);
  float3 blue = float3(0.0, 0.0, 1.0);
  
  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = worldCoordAspectAdjusted;
                                                 // head
  float3 head = DrawCircle(uv, float2(0.0,0.0), 0.5, 0.1, red, blue);
  // eye
  float3 leftEye = DrawCircle(uv, float2(0.0,0.0), 0.2, 0.1, head, green);
  
  
  float3 lastCol = leftEye;
  // Output to screen
  return float4(lastCol,1.0);
}
