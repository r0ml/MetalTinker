
#define shaderName Radar

#include "Common.h"

fragmentFn() {
  float2 c = worldCoordAspectAdjusted;
  float2 k = .1-.1*step(.007,abs(c));
  float x = 27 * length(c); // x,y - polar coords
  float y = mod(atan2(c.y, c.x) + uni.iTime, TAU);
  float d = max(0.0, 0.75 - y * .4);
  float b = min( min( length(c - 0.1 * float2(-3,-1)),   length(c - 0.1 * float2(6, -4)) ), length(c - 0.1 * float2(4,5) ) ) + 0.06 - y * 0.04;

  float r = (b < 0.08) * b * max(0.0, 18 - 13 * y); // target

  //                        background                 grid                          detector      ray
  float g = ( x < 24 ) * ( 0.25 + max(0.0, cos(x+0.8) - 0.95 ) * 2.4 + k.x + k.y + d * d + max(0.0, 0.8 - y * (x + x + 0.3)));

  return float4( r, g + max(0.0, 1. - abs(x+x-48.) ), 0.1, 1);
}
