
#define shaderName Derivatives_test

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 b = textureCoord;
  float3  col = tex.sample( iChannel0, b).xyz;
  float lum = dot(col,float3(0.333));
  float3 ocol = col;
  
  if( b.x>0.5 ) {
    // right side: changes in luminance
    float f = fwidth( lum );
    col *= 1.5*float3( saturate(1.0-8.0*f) );
  } else {
    // bottom left: emboss
    float3  nor = normalize( float3( dfdx(lum), 64.0 * scn_frame.inverseResolution.x, dfdy(lum) ) );
    if( b.x<0.5 ) {
      float lig = 0.5 + dot(nor,float3(0.7,0.2,-0.7));
      col = float3(lig);
    } else {
      // top left: bump
      float lig = clamp( 0.5 + 1.5*dot(nor,float3(0.7,0.2,-0.7)), 0.0, 1.0 );
      col *= float3(lig);
    }
  }
  
  col *= smoothstep( 0.003, 0.004, abs(b.x-0.5) );
  col *= 1.0 - (1.0-smoothstep( 0.007, 0.008, abs(b.x-0.5) ))*(1.0-smoothstep(0.49,0.5,b.x));
  col = mix( col, ocol, pow( 0.5 + 0.5*sin(scn_frame.time), 4.0 ) );
  
  return float4( col, 1.0 );
}


