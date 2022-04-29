/** 
 Author: FabriceNeyret2
 A variant of graffiti3 [url]https://www.shadertoy.com/view/XdjcRD[/url]
 
 Change parameters, uncomment, try fullscreen.
 */

#define shaderName maze_worms_graffitis_3b

#include "Common.h" 

#define CS(a)  float2(cos(a),sin(a))
#define rnd(x) ( 2.* fract(456.68*sin(1e3*x+mod(uni.iDate.w,100.))) -1.) // NB: mod(t,1.) for less packed pattern
#define T(U) textureLod(lastFrame, iChannel0, (U)/R, 0.)
constant const float r = 1.5, N = 50., da = .5 // width , number of worms , turn angle at hit
 ;            // sinusoidal path parameters: L straight + l turn

fragmentFn( texture2d<float> lastFrame ) {

// ============================================== buffers ============================= 

  float4 O = 0;
  float2 U = thisVertex.where.xy;
  float2 R = uni.iResolution;
  
  if (T(R).x==0.) { U = abs(U/R*2.-1.); O  = float4(max(U.x,U.y)>1.-r/R.y); O.w=0.;
    return O;
  }
  
  if (U.y==.5 && T(U).w==0.) {                           // initialize heads state: P, a, t
    O = float4( R/2. + R/2.4* float2(rnd(U.x),rnd(U.x+.1)) , PI * rnd(U.x+.2), 1);
    if (T(O.xy).x>0.) O.w = 0.;                        // invalid start position
    return O;
  }
  
  O = T(U);
  
  for (float x=.5; x<N; x++) {                           // draw heads
    float4 P = T(float2(x,.5));                            // head state: P, a, t
    if (P.w>0.) O += smoothstep(r,0., length(P.xy-U))  // draw head if active
      *(.5+.5*sin(.01*P.w+float4(0,-2.1,2.1,1)));  // coloring scheme
  }
  
  if (U.y==.5) {                                         // head programms: worm strategy
    float4 P = T(U);                                     // head state: P, a, t
    if (P.w>0.) {                                      // if active
      float a = P.z;
      a -= 1./sqrt(P.w);
      //a -= 10./sqrt(P.w);
      //a -= 100./sqrt(P.w);
      //a -= 1000./sqrt(P.w);
      // if  ( T(P.xy+(r+2.)*CS(a)).w > 0. )  { O.w = 0.; return; }
      while ( T(P.xy+(r+2.)*CS(a)).w > 0. && a < 13. )  a += da; // hit: turn
      if (a>=13.) {
        O.w = 0.;
        return O;
      }              // stop head
      O = float4(P.xy+CS(a),mod(a,TAU),P.w+1.);     // move head
    }
  }
  return O;
}