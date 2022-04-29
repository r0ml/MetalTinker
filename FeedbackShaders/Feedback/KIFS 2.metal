
#define shaderName kifs_2

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {

  const int Z = 5;                   // recursion depth

  float2 R = uni.iResolution,
  U = 1.2 * ( thisVertex.where.xy+thisVertex.where.xy - R ) / R.y,
  M = uni.iMouse.xy , z;

  float T = .5*uni.iTime, k=.95;
  if ( !uni.wasMouseButtons )      // auto-demo
    M = .5 + .4 *float2( cos(T)-.4*sin(2.7*T), sin(1.73*T)-.3*cos(2.3*T) ) / 1.4,
    k = .98;                      // relaxation duration

  float s = (.5+.5*M.x)/2.;         // scaling
  float t = 1.-s;                   // translation
  float a = PI*M.y;               // rotation
  float4 fragColor = k * lastFrame.read( uint2( thisVertex.where.xy ) ) * float4( .96, .98, 1, 0); // relaxation


  z = U;
  for( int i=0; i<Z; i++ ) { // --- iterate up to depth N. should be log(1/R.y)/log(s)
    z = abs(z);
    z = (z-float2(t,t))* rot2d(-a) / s;
  }

  fragColor += smoothstep(.01,0.,length(z)-1.) ;
  return saturate(fragColor);
}
