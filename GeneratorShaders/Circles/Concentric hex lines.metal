
#define shaderName Concentric_hex_lines

#include "Common.h"

fragmentFunc() {
  float time = scn_frame.time;
  float2 uv = worldCoordAdjusted;
  uv = uv * rot2d( PI * 0.25);
  float rads = atan2(uv.x, uv.y);
  float vertices = 6.;
  float baseRadius = 0.7;
  float extraRadius = 0.03 + 0.03 * sin(time * 0.5);
  float curRadius = baseRadius + extraRadius * sin(rads * vertices);
  // float2 edge = float2(curRadius * sin(rads), curRadius * cos(rads));
  float2 edge = curRadius* normalize(uv);
  float distFromCenter = length(uv);
  float distFromEdge = distance(edge, uv);
  float freq = 24.;
  if(distFromCenter > curRadius) freq *= 3.;
  float col = smoothstep(0.25, 0.75, abs(sin(time + distFromEdge * freq)));
  col += distFromCenter * 0.1;
  return float4(col);
}
