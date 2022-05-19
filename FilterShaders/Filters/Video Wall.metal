
#define shaderName video_wall

#include "Common.h" 

constant const float BOXES = 10.;
constant const float MIN_BRIGHTNESS = 0.3;

fragmentFunc(texture2d<float> tex) {
  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = textureCoord;
  
  float2 px = uv * BOXES;
  
  // Decide the shade of each panel
  float shade = saturate(MIN_BRIGHTNESS + rand(floor(px + 0.5)) );
  
  // Calculate the grid
  float g = smoothstep(0.4, 0.49, distance(floor(px.x + 0.5), px.x))
  + smoothstep(0.4, 0.49, distance(floor(px.y + 0.5), px.y));
  g = 1. - saturate(g);
  
  float3 col = tex.sample(iChannel0, uv).rgb;
  
  // Output to screen
  return float4(g * shade * col, 1.);
}
