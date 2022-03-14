
#define shaderName Bokeh_Paralax

#include "Common.h"

struct InputBuffer {  };
initialize() {}

static float Circle( float2 p, float r )
{
  return ( length( p / r ) - 1.0 ) * r;
}

static void BokehLayer( thread float3& color, float2 p, float3 c )
{
  float wrap = 450.0;
  if ( mod( floor( p.y / wrap + 0.5 ), 2.0 ) == 0.0 )
  {
    p.x += wrap * 0.5;
  }
  
  float2 p2 = mod( p + 0.5 * wrap, wrap ) - 0.5 * wrap;
  float2 cell = floor( p / wrap + 0.5 );
  float cellR = rand( cell );
  
  c *= fract( cellR * 3.33 + 3.33 );
  float radius = mix( 30.0, 70.0, fract( cellR * 7.77 + 7.77 ) );
  p2.x *= mix( 0.9, 1.1, fract( cellR * 11.13 + 11.13 ) );
  p2.y *= mix( 0.9, 1.1, fract( cellR * 17.17 + 17.17 ) );
  
  float sdf = Circle( p2, radius );
  float circle = 1.0 - smoothstep( 0.0, 1.0, sdf * 0.04 );
  float glow	 = exp( -sdf * 0.025 ) * 0.3 * ( 1.0 - circle );
  color += c * ( circle + glow );
}

fragmentFn() {
  float2 uv = textureCoord;
  float2 p = worldCoordAspectAdjusted * 1000.0;
  
  // background
  float3 color = mix( float3( 0.3, 0.1, 0.3 ), float3( 0.1, 0.4, 0.5 ), dot( uv, float2( 0.2, 0.7 ) ) );
  
  float time = uni.iTime - 15.0;
  
  p = p * rot2d( 0.2 + time * 0.03 );
  BokehLayer( color, p + float2( -50.0 * time +  0.0, 0.0  ), 3.0 * float3( 0.4, 0.1, 0.2 ) );
  p = p * rot2d( 0.3 - time * 0.05 );
  BokehLayer( color, p + float2( -70.0 * time + 33.0, -33.0 ), 3.5 * float3( 0.6, 0.4, 0.2 ) );
  p = p * rot2d( 0.5 + time * 0.07 );
  BokehLayer( color, p + float2( -60.0 * time + 55.0, 55.0 ), 3.0 * float3( 0.4, 0.3, 0.2 ) );
  p = p * rot2d( 0.9 - time * 0.03 );
  BokehLayer( color, p + float2( -25.0 * time + 77.0, 77.0 ), 3.0 * float3( 0.4, 0.2, 0.1 ) );
  p = p * rot2d( 0.0 + time * 0.05 );
  BokehLayer( color, p + float2( -15.0 * time + 99.0, 99.0 ), 3.0 * float3( 0.2, 0.0, 0.4 ) );
  
  return float4( color, 1.0 );
}
