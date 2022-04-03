
#define shaderName Colored_Rings

#include "Common.h" 
struct InputBuffer {
    int3 rings;
    float3 ring_width;
};

initialize() {
  in.rings = int3(5, 11, 20);
  in.ring_width = float3(20, 30, 40);
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  float d = (uni.iResolution.y / in.ring_width.y) * distance(uv, 0);
  float hue = floor(d) / 20. + uni.iTime * .1;
  float fd = fract(d);
  float value = 0.9 * smoothstep(0., .2, fd) * smoothstep(.9, .7, fd);   // space between rings
  value = value * (d > 2) * (d < (in.rings.y+2));
  
  float3 hsv = float3(hue, .75, value);
  return float4( hsv2rgb(hsv), 1);
}
