
#define shaderName Color_Selection_Wheel

#include "Common.h"

struct InputBuffer {  };
initialize() {}






static float2 remap(float2 coord, float2 reso) {
  return coord /min(reso.x,reso.y);
}

/*static float lerp(float a, float b, float t) {
  return a + (a - b) * t;
}*/

static float circle(float2 uv, float2 pos, float rad) {
  return 1.0 - smoothstep(rad,rad+0.005,length(uv-pos));
}

static float ring(float2 uv, float2 pos, float innerRad, float outerRad) {
  return (1.0 - smoothstep(outerRad,outerRad+0.005,length(uv-pos))) * smoothstep(innerRad,innerRad+0.005,length(uv-pos));
}

fragmentFn() {
  float2 uv = textureCoord * aspectRatio;
  
  float2 t = remap(uni.iMouse.xy * uni.iResolution.xy, uni.iResolution);
  
  float3 col = float3(0.0);
  
  float2 center = float2(0.5*uni.iResolution.x/uni.iResolution.y,0.5);
  
  float2 d = uv - center;
  float a = atan2(d.x,d.y)*PI*0.05;
  
  col += ring(uv,center,0.47,0.5) * hsv2rgb(float3(a,1.0,0.5));
  
  d = t - center;
  a = atan2(d.x,d.y)*PI*0.05;
  
  col += circle(uv,center,0.2) * hsv2rgb(float3(a,1.0,0.5));
  
  return float4(col, 1.0);
}
