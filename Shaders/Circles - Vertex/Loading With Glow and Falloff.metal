
#define shaderName loading_with_glow_and_falloff

#include "Common.h" 

struct InputBuffer {};
initialize() {}


fragmentFn() {
  const float pixelSize = 1.0/min(uni.iResolution.x, uni.iResolution.y);
  
  const float radius = 0.3;
  const float glowSize = 5.0 * pixelSize * 2; // in pixels
  float lineWidth = 5.0 * pixelSize; // in pixels
  
  float2 uv = worldCoordAspectAdjusted / 2;
  
  const float len = length(uv);
  const float angle = atan2(uv.y, uv.x);
  const float fallOff = fract(-0.5*(angle/M_PI_F)-uni.iTime*0.5);
  
  lineWidth = (lineWidth-pixelSize)*0.5*fallOff;
  
  const float arl = abs(radius-len) - lineWidth;
  
  return smoothstep(pixelSize, 0.0, arl)*fallOff
  + smoothstep(glowSize*fallOff, 0.0, arl)*fallOff*0.5;
  
}
