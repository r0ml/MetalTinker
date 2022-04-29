/** 
Author: FabriceNeyret2
2 levels particle hierarchy.

Change parameters, uncomment choices, try fullscreen.
*/

#define shaderName maze_worms_graffitis_4

#include "Common.h" 

struct KBuffer {
};
initialize() {}

 


fragmentFn1() {
  FragmentOutput fff;
    fff.fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy/uni.iResolution.xy);

 // ============================================== buffers ============================= 


 #define CS(a)  float2(cos(a),sin(a))
#define rnd(x) ( 2.* fract(456.68*sin(1e3*x+mod(uni.iDate.w,100.))) -1.) // NB: mod(t,1.) for less packed pattern
#define T(U) renderInput[0].sample(iChannel0, (U)/R)
#define BG  0.   // background = black (0) or white (1) 
const float r = 1.5, K=20., N = K*10.; // width , number of level2 and 1 particles , turn angle at hit

  float4 O = 0;
  float2 U = thisVertex.where.xy;
    float2 R = uni.iResolution;
    float4 P;
    
    if (T(R).x==0.) { U = abs(U/R*2.-1.); O = BG+float4(max(U.x,U.y)>1.-r/R.y); O.w=0.; return fff; } // frame
    O = T(U);                                              // previous state

    if (U.y==.5) { // --- particle zone
        if (U.x<N && T(U).w==0.) {  // --- free particle.  initialize heads state: P, a, t
            float n = mod(U.x-.5,K);
            if (n==0.)                                     // primary particle
                O = float4( R/2. + R/2.4* float2(rnd(U.x),rnd(U.x+.1)) , PI * rnd(U.x+.2), 1); // init
            else {                                         // secondary particle
                float4 P = T( float2(floor(U.x/K)*K+.5,.5) );  // parent particle state
              //if (P.w > 0.)                              // parent is active
                if (P.w/(2.*r) == n)                       // emit time (parent rel)
                    O = float4( P.xy , P.z-1.*sign(mod(n,2.)-.5), 1), O.xy+=3.*r*CS(O.z); // init
               }
            if (T(O.xy).w>0.) O.w = 0.;                    // invalid start position
            P = O;
        }        
        else P = T(U);                                     // head state: P, a, t
        // --- particle engine
        if (P.w>0.) {                                      // if active
            float n = mod(U.x-.5,K),                       // parent partic or secondary number
                  a = P.z;
            if (n==0.) a += .0005*P.w * sign(sin(U.x));    // parent particle
            else       a += .002*P.w * sign(mod(n,2.)-.5); // secondary particle
          //a += .01*P.w;
          //a += 1./P.w;
          //a += 1./sqrt(P.w);
            if  ( T(P.xy+(r+2.)*CS(a)).w > 0. )  { O.w = 0.; return fff; } // hit: die
            O = float4(P.xy+CS(a),mod(a,TAU),P.w+1.);     // move head
            if (n==0.) { if (P.w>60.) O.w=0.; }            // end by age
            else         if (P.w>30.*(1.-n/K)) O.w=0.;
        }
        return fff;
    }
    
    // --- plain screen: draw particles
    
    for (float x=.5; x<N; x++) {                           // draw heads
        if (R.y < 200. && x>5.*K) break;                   // less strand for icon
        float4 P = T(float2(x,.5));                            // head state: P, a, t
        float n = mod(x-.5,K);                             // parent partic or secondary number
        if (P.w>0.) 
            O = mix( O,                                    // draw head if active
                 n==0. ? float4(.7,.4,.4,1) : float4(0,.7,0,1),// coloring scheme
                 smoothstep(r,0., length(P.xy-U)) );
          //O += smoothstep(r,0., length(P.xy-U))          // draw head if active
          //    * (n==0. ? float4(.5,.3,.3,1) : float4(0,.5,0,1) ); // coloring scheme
       }
  fff.pass1 = O;
  fff.pass1.w = 1;
  return fff;
}
