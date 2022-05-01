
#define shaderName ryb_color_wheel

#include "Common.h" 

static float3 hsv2rgb_subtractive( float3 c ) {
  float frac = fract(c.x)*6.0;
  float3 col = smoothstep(float3(3,0,3),float3(2,2,4),float3(frac));
  col += smoothstep(float3(4,3,4),float3(6,4,6),float3(frac)) * float3(1, -1, -1);
  return mix(float3(1), col, c.y) * c.z;
}

fragmentFn() {
  float2 uv = textureCoord;
  float2 p = worldCoordAspectAdjusted;

  float4 fragColor = 0;
  
  float frac = (atan2(p.x, -p.y) + PI) / (2.0 * PI);
  frac += 1.0/3.0;
  frac = floor(frac*12.0+0.5)/12.0;

  fragColor.rgb = hsv2rgb_subtractive( float3(frac, 1, 1) );
  float3 back = hsv2rgb_subtractive( float3( uv.x, uv.y, 1.0 - uv.y) );
  float l = abs(length(p) - 0.7);

  return float4( mix(fragColor.rgb, back, smoothstep(0.20, 0.21, l)), 1);

}
