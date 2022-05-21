
#define shaderName metaballs_01

#include "Common.h"

#define NUM_BALLS 8
#define RADIUS 0.02
#define MOVING_RADIUS 0.02

fragmentFunc() {
  float2 aspect = nodeAspect;
  float2 st = textureCoord * aspect;

  float t = scn_frame.time;
  float3 col = float3(0.);
  float mi_total = 0.0;
  
  float2 c0 = float2(cos(t), sin(t))*0.3+0.5*aspect;

  float d0 = distance(st, c0);
  float m0 = MOVING_RADIUS/d0;
  col += m0*float3(1, 1, 1);
  
  for (int i=0; i<NUM_BALLS;i++) {
    float2 ci = float2(cos(-t*0.5+float(i)*TAU/float(NUM_BALLS)),
                       sin(-t*0.5+float(i)*TAU/float(NUM_BALLS)))*0.3+0.5 * aspect;
    float d = distance(st, ci);
    float mi = RADIUS/d;
    mi_total += mi;
    col += mi*palette(float(i)/float(NUM_BALLS),
                      float3(0.5,0.5,0.5),
                      float3(0.5,0.5,0.5),
                      float3(1.0,1.0,1.0),
                      float3(0.0,0.33,0.67));
  }
  
  float m = smoothstep(0.2, 2.0, m0+mi_total);
  float3 color = (col);
  
  return float4(color*m, 1.0);
}
