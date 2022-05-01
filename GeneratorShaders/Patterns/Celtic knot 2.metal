
#define shaderName celtic_knot_2

#include "Common.h" 

struct InputBuffer { };
initialize() {}

#define S(l,r,e)  smoothstep( 4./uni.iResolution.y, 0., abs(l-r) -e )            // base thick ring antialiased

#define D(U,r,z) ( l=length(U) , a = atan2((U).x,(U).y),    \
S(l,r,.08 )  * float4( float3(1.-S(l,r,.03)) , z )) // band pattern (col,Z)

#define Z         (-.105 + cos( a ) ) * (1. - .05*T )              // Z arc + Z knot modulation

#define T         sin( -3.*a )                                     // Z modulation for knot

#define M(a)      fragColor =  a.w > fragColor.w ? a : fragColor ;                 \
U *= float2x2(-.5,-.866,.866,-.5);                   // Z-buffer draw + rotate

#define B         M( D( U +float2(0,d), r , Z ) )                    // draw arc


fragmentFn() {
  float2 U = worldCoordAspectAdjusted;
  U.y += .2;
  float l,a, d=.6, r=.8;
  
  float4 fragColor = 0;
  fragColor.rgb += .5; // comment if you prefer black background
  
  M( D(U,.6,.5+.5*T) );    // ring
  B; B; B;                 // 3 arcs
  return float4(fragColor.rgb, 1);
}


