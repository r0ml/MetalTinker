
#define shaderName rounded_loading_spinner

#include "Common.h" 

struct InputBuffer {};
initialize() {}

constant float THICCNESS = 0.03;
constant float RADIUS = 0.2;
constant float SPEED = 4.0;

static float circle(float2 uv, float2 pos, float rad) {
  return 1.0 - smoothstep(rad,rad+0.005,length(uv-pos));
}

static float ring(float2 uv, float2 pos, float innerRad, float outerRad, float2 reso) {
  float aa = 2.0 / min(reso.x,reso.y);
  return (1.0 - smoothstep(outerRad,outerRad+aa,length(uv-pos))) * smoothstep(innerRad-aa,innerRad,length(uv-pos));
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  
  float geo = ring(uv,float2(0.0),RADIUS-THICCNESS,RADIUS, uni.iResolution);
  
  uv = rot2d(-uni.iTime * SPEED) * uv;
  
  float a = atan2(uv.x,uv.y)*PI*0.05 + 0.5;
  
  a = max(a,circle(uv,float2(0.0,-RADIUS+THICCNESS/2.0),THICCNESS/2.0));
  
  return float4(a*geo);
}
