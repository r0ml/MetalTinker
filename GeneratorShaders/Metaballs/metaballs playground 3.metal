
#define shaderName metaballs_playground_3

#include "Common.h" 


#define S(v,r)  smoothstep(5 * scn_frame.inverseResolution.y,0., v-r)

static float value(float2 p1, float2 p2) {
  //return 0.078 / distance(p1, p2);
  float dist = distance(p1, p2) * 2.0;
  return 0.5 * exp(-dist * dist);
}

fragmentFunc() {
  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = worldCoordAdjusted * 1.5;
  float t = scn_frame.time;

  float2 b1 = float2(sin(t), cos(t));
  float2 b2 = float2(sin(-t * 1.42386 + 50.0), cos(-t * 1.42386 + 50.0) * 0.6);
  float2 b3 = float2(sin(t * 1.21239 + 50.0) * 0.2, -cos(t * 1.21239 + 50.0));
  
  // Time varying pixel color
  float val = 0.0;
  val += value(uv, b1);
  val += value(uv, b2);
  val += value(uv, b3);
  
  float3 d = float3( distance(uv, b1), distance(uv, b2), distance(uv, b3) );
  float3 col = S(d,.1);
  col += (1.-min(1.,col.r+col.g+col.b)) * (1.-S(val,.4));
  
  // Output to screen
  return float4(col,1.0);
}
