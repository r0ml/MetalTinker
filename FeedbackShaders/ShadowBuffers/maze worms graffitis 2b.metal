
// FIXME: completely broken

#define shaderName maze_worms_graffitis_2b

#include "Common.h" 


#define CS(a)  float2(cos(a),sin(a))

static float rnd(float x, float time) {
  return ( 2.* fract(456.68*sin(1e4*x+mod(time,50.))) -1.); // NB: mod(t,1.) for less packed pattern
}

constant const float r = 1.5, N = 50., da = .5, // width , number of worms , turn angle at hit
L = 10., l= 4.;            // sinusoidal path parameters: L straight + l turn

fragmentFn( texture2d<float> lastFrame ) {

  float2 U = thisVertex.where.xy;
  float2 R = uni.iResolution;
  float4 O = 0;
  
  // is this "first time thru?"
  if (lastFrame.read(uint2(uni.iResolution)).x==0.) {
    U = abs(U/R*2.-1.);
    O  = float4(max(U.x,U.y)>1.-r/R.y);
    O.w=0.;
    return O;
  }
  
  if (thisVertex.where.y < 1 && lastFrame.read(uint2(thisVertex.where.xy)).w==0.) {                           // initialize heads state: P, a, t
    O = float4( R/2. + R/2.4* float2(rnd(U.x, uni.iDate.w),rnd(U.x+.1, uni.iDate.w)) , PI * rnd(U.x+.2, uni.iDate.w), 1);
    if ( lastFrame.read(uint2(O.xy)).x>0.) O.w = 0.;                        // invalid start position
    return O;
  }
  
  O = lastFrame.read(uint2(U));
  //  float2 M = uni.iMouse.xy; if (length(M)>0.) O += smoothstep(r,0., length(M-U));
  
  for (float x=.5; x<N; x++) {                           // draw heads
    float4 P = lastFrame.read(uint2(x,0));                            // head state: P, a, t
    if (P.w>0.) O += smoothstep(r,0., length(P.xy-U))  // draw head if active
      *(.5+.5*sin(.01*P.w+float4(0,-2.1,2.1,1)));  // coloring scheme
  }
  
  if (U.y==.5) {                                         // head programms: worm strategy
    float4 P = lastFrame.read(uint2(U));                                     // head state: P, a, t
    if (P.w>0.) {                                      // if active
      float a = P.z, m = mod(P.w,L+L+l+l);
      if (m>=L && m<L+l) a += PI/l;
      else if (m>=L+L+l && m<L+L+l+l) a -= PI/l;
      while ( lastFrame.read( uint2(P.xy+(r+2.)*CS(a))) .w > 0. && a < 13. )  a += da; // hit: turn
      if (a>=13.) {
        O.w = 0.;
        return O;
      }              // stop head
      //a += .004;
      O = float4(P.xy+CS(a),mod(a,TAU),P.w+1.);     // move head
    }
  }
  
  return O;
}

