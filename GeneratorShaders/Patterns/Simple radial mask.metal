
#define shaderName simple_radial_mask

#include "Common.h" 

fragmentFunc(constant float2& mouse) {
  float2 uv = textureCoord;
  
  float r_in = 0.15;         // inner limit of the mask
  float r_out = 0.2;        // outer limit of the mask
                            // inner-outer = grey transition from white to black
                            // if inner>outer, the transition inverses from white->black to black->white
  
  float2 pos =   mouse;
  float radius = length( (uv-pos) * nodeAspect );
  float mask = ( radius-r_in ) / ( r_out-r_in );
  return float4( mask );
}
