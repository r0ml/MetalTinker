/** 
 Author: FabriceNeyret2
 just a variant of graffiti 3 [url]https://www.shadertoy.com/view/XdjcRD[/url]
 
 Change parameters, uncomment choices, try fullscreen.
 */

#define shaderName maze_worms_graffitis_3d

#include "Common.h" 

struct KBuffer {
};
initialize() {}


#define CS(a)  float2(cos(a),sin(a))
#define rnd(x) ( 2.* fract(456.68*sin(1e4*x+mod(uni.iDate.w,100.))) -1.) // NB: mod(t,1.) for less packed pattern

// #define T(U) inTexture.sample(iChannel0, (U)/R)

constant const float r = 1.5, N = 50. // width , number of worms , turn angle at hit
;            // sinusoidal path parameters: L straight + l turn


fragmentFn2() {
  FragmentOutput fff;

  fff.fragColor = renderInput[0].read(uint2(thisVertex.where.xy));
  fff.fragColor.w = 1;

// ============================================== buffers ============================= 

  float4 O = 0;
  float2 U = thisVertex.where.xy;
  float2 R = uni.iResolution;
  
  if (renderInput[0].sample(iChannel0, 1).x==0.) { U = abs(U/R*2.-1.); O  = float4(max(U.x,U.y)>1.-r/R.y); O.w=0.;
    fff.pass1 = O;
    return fff; }
  
  if (U.y==.5 && renderInput[0].sample(iChannel0, U/R).w==0.) {                           // initialize heads state: P, a, t
    O = float4( R/2. + R/2.4* float2(rnd(U.x),rnd(U.x+.1)) , PI * rnd(U.x+.2), 1);
    if ( renderInput[0].sample(iChannel0, O.xy / R).x>0.) O.w = 0.;                        // invalid start position
    fff.pass1 = O;
    return fff;
  }
  
  O = renderInput[0].sample(iChannel0, U/R);
  
  for (float x=.5; x<N; x++) {                           // draw heads
    if (R.y < 200. && x>5.) break;                    // less strand for icon
    float4 P =  renderInput[0].sample(iChannel0, float2(x,.5 )/ R);                            // head state: P, a, t
    if (P.w>0.) O += smoothstep(r,0., length(P.xy-U))  // draw head if active
      *mix(float4(0,.5,0,1),float4(1,.5,1,1),.01*P.w);  // coloring scheme
  }
  
  if (U.y==.5) {                                         // head programms: worm strategy
    float4 P = renderInput[0].sample(iChannel0, U/R);                                     // head state: P, a, t
    if (P.w>0.) {                                      // if active
      float a = P.z;
      a += .001*P.w * sign(sin(U.x));
      //a += .01*P.w;
      //a += 1./P.w;
      //a += 1./sqrt(P.w);
      if  ( renderInput[0].sample(iChannel0, (P.xy+(r+2.)*CS(a)) / R ).w > 0. )  {
        O.w = 0.;
        fff.pass1 = O;
        return fff; }
      O = float4(P.xy+CS(a),mod(a,TAU),P.w+1.);     // move head
    }
  }
  fff.pass1 = O;
  return fff;
}

