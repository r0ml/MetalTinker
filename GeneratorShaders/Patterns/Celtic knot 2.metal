
#define shaderName celtic_knot_2

#include "Common.h" 

#define S(lr,e)  smoothstep( 0, 5. * scn_frame.inverseResolution.y, e - lr )            // base thick ring antialiased

fragmentFunc() {
  float2 U = worldCoordAdjusted;
  U.y += .2;
  float l,a, d=.6;
  float rrr=.8;

  float4 fragColor = 0;
  fragColor.rgb += .5; // gray background

  float4 ma;
  float z;
  float t;
  float lr;

  // ring
  rrr = 0.6;
  l=length(U);
  a = atan2((U).x,(U).y);
  t = sin( -3.*a ) ;
  z = .5 + .5 * t;

  lr = abs(l-rrr);
  ma = S(lr,.08 )  * float4( float3(1.-S(lr,.03)) , z );

  fragColor =  ma.w > fragColor.w ? ma : fragColor ;
  U *= float2x2(-.5,-.866,.866,-.5);


  // the three arcs

  float2 UU;
  rrr = 0.8;
  UU = U+float2(0, d);
  l = length(UU);
  a = atan2(UU.x, UU.y);
  t = sin( -3.*a ) ;
  z = (-.105 + cos( a ) ) * (1. - .05*t ) ;
  lr = abs(l-rrr);
  ma = S(lr,.08 )  * float4( float3(1.-S(lr,.03)) , z );

  fragColor =  ma.w > fragColor.w ? ma : fragColor ;
  U *= float2x2(-.5,-.866,.866,-.5);

  UU = U+float2(0, d);
  l = length(UU);
  a = atan2(UU.x, UU.y);
  t = sin( -3.*a ) ;
  z = (-.105 + cos( a ) ) * (1. - .05*t ) ;
  lr = abs(l-rrr);
  ma = S(lr,.08 )  * float4( float3(1.-S(lr,.03)) , z );

  fragColor =  ma.w > fragColor.w ? ma : fragColor ;
  U *= float2x2(-.5,-.866,.866,-.5);

  UU = U+float2(0,d);
  l = length(UU);
  a = atan2(UU.x, UU.y);
  t = sin( -3.*a ) ;
  z = (-.105 + cos( a ) ) * (1. - .05*t ) ;
  lr = abs(l-rrr);
  ma = S(lr,.08 )  * float4( float3(1.-S(lr,.03)) , z );

  fragColor =  ma.w > fragColor.w ? ma : fragColor ;
  U *= float2x2(-.5,-.866,.866,-.5);

  return float4(fragColor.rgb, 1);
}


