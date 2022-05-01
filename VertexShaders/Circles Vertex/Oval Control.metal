
#define shaderName oval_control

#include "Common.h" 

fragmentFn() {
  float size = 1.0 - smoothstep(0, 1, uni.iMouse.x );
  float hardness = 1.0 - smoothstep(0.0, 1, uni.iMouse.y );
  
  float2 trans = worldCoordAspectAdjusted;
  float part = -dot(trans, trans) + 1.0;
  
  float calc = smoothstep(size, size + hardness, part);
  
  return float4(calc, calc, calc, 1);
}
