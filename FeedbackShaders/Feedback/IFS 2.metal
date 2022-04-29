
#define shaderName ifs_2

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {

  const float N = 20., Z = 10.;

#define rnd(U,s)   fract( 1e4* sin( U.x*73.+U.y*7. + s) )
#define srnd(U,s) ( 2.* rnd(U,s) - 1. )

  float2 R = uni.iResolution.xy;
  float2 U = 1.2* ( thisVertex.where.xy+thisVertex.where.xy - R ) / R.y;
  float2 M = uni.iMouse.xy, z;
  
  float T = .2*uni.iTime, k=.95;
  if ( length(uni.iMouse.xy * uni.iResolution)<10. )      // auto-demo
    M = .5 + .4 *float2( cos(T)-.4*sin(2.7*T), sin(1.73*T)-.3*cos(2.3*T) ) / 1.4,
    k = .98;                      // relaxation duration
  
  float p, s, s0 = M.x,             // scaling
  r, t, t0 = 1.-s0,           // translation
  a, a0 = PI*M.y;        // rotation
  float4 fragColor = k * lastFrame.read(uint2(thisVertex.where.xy)) * float4( .96, .98, 1, 1); // relaxation
  
  s = s0, t = t0, a = a0;
  for( float n=0.; n<N; n++ ) {     // --- cumulates N tries per pixel
    z = U; float4 C = float4(1);
    //z = float2(rnd(1.1*U,0.),rnd(.7-1.3*U,0.));
    for( float i=0.; i<Z; i++ ) { // --- iterate up to depth N. should be log(1/R.y)/log(s)
      r = uni.iTime+i*.93-.11*n;
      //s = s0, t = t0, a = a0;   // random variations
      //a += .1* srnd(U,r+.3);
      //s += .1* srnd(U,r+.3);
      p = rnd(U, r);            // chose one of these 4 transforms:
      z =   p < .25 ? s * z* rot2d( a) + float2(-t,-t)
      : p < .50 ? s * z* rot2d(-a) + float2( t,-t)  // try +a
      : p < .75 ? s * z* rot2d(-a) + float2(-t, t)  //
      :           s * z* rot2d( a) + float2( t, t) ;
      fragColor += 3e-3/N/Z / dot(U-z,U-z) *C;  // draw dot z - prettier
      C *= float4(1,.93,.86,1);
    }
    //O += 3e-3/N / dot(U-z,U-z);   // draw final dot z - true IFS
  }
  return fragColor;
}
