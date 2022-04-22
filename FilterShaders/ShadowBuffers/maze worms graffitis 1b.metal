
// FIXME: completely broken

#define shaderName maze_worms_graffitis_1b

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {

// ============================================== buffers =============================


#define CS(a)  float2(cos(a),sin(a))
#define rnd(x) ( 2.* fract(456.68*sin(1e4*x+mod(uni.iTime,50.))) -1.) // NB: mod(t,1.) for less packed pattern
#define T(U) lastFrame.read(uint2(U))
  const float r = 1.5, N = 150., da = .01; // width , number of worms , turn angle at hit
  
  
  float2 U = thisVertex.where.xy;
  float2 R = uni.iResolution;
  float4 O = 0;
  
  if (T(0).x==0.) {
    U = abs(U/R*2.-1.);
    O  = float4(max(U.x,U.y)>1.-r/R.y);
    O.w=0.;
    return O; }
  
  if (thisVertex.where.y < 1 && T(U).w==0.) {                           // initialize heads state: P, a, t
    O = float4( R/2. + R/2.4* float2(rnd(U.x),rnd(U.x+.1)) , PI * rnd(U.x+.2), 1);
    if (T(O.xy).x>0.) O.w = 0.;                        // invalid start position
    return O;
  }
  
  O = T(thisVertex.where.xy);
  //  float2 M = uni.iMouse.xy; if (length(M)>0.) O += smoothstep(r,0., length(M-U));
  
  for (int x=0; x<N; x++) {                           // draw heads
    float4 P = T(int2(x,0));                            // head state: P, a, t
    if (P.w>0.) O += smoothstep(r,0., length(P.xy-U))  // draw head if active
      // *float4(1.-.01*P.w,1,0,1);          // coloring scheme
      *(.5+.5*sin(TAU*x/N+float4(0,-2.1,2.1,1)));   // coloring scheme
  }
  
  if (thisVertex.where.y < 1) {                                         // head programms: worm strategy
    float4 P = T(thisVertex.where.xy);                                     // head state: P, a, t
    if (P.w>0.) {                                      // if active
      float a = P.z;
      while ( T(P.xy+(r+2.)*CS(a)).w > 0. && a < 13. )  a += da; // hit: turn
      if (a>=13.) { O.w = 0.;
        return O;
      }              // stop head
      a += .004;
      O = float4(P.xy+CS(a),mod(a,TAU),P.w+1.);     // move head
      
    }
  }
  return O;
}

