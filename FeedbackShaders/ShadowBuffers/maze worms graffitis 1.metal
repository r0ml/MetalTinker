
// FIXME: completely broken

#define shaderName maze_worms_graffitis_1
#define SHADOWS 2

#include "Common.h" 

constant const float r = 1.5;
// constant const float da = .5; // width , turn angle at hit
constant const int N = 100.; // number of worms

struct MyBuffer {
  float4 head[N];
};

// I want to have a texture passed in here -- in this case renderInputp[0], but I might need to specify another
frameInitialize(device struct MyBuffer &buf) {
  if (uni.iFrame == 0) {
    for (int i = 0; i < N; i++) {
      float4 o = float4(  uni.iResolution * rand2( float(i) * uni.iResolution / N ) , PI * rand(float(i) * uni.iResolution / N +.2), 1);
      buf.head[i]=o;
    }
  } else {

    for(int i = 0; i<N; i++ ) {
    float4 P = buf.head[i];
      if (P.w>0.) {                                      // if active
        float a = P.z;
        // If I hit something, turn



      // In order to do this properly, I need access to the lastFrame[1] texture
        /*
    while ( T(P.xy+(r+2.)*float2(cos(a), sin(a))).w > 0. && a < 13. ) {
        a += da; // hit: turn
      }

    // After 13 turns, give up and disable
    if (a>=13.) {
        O.w = 0.;
        f.pass1 = O;
        return f;
      }              // stop head
    */
        a += .004;
        buf.head[i] = float4(P.xy+float2(cos(a), sin(a)),mod(a,TAU),P.w+1.);     // move head
    }
    }
}
}

fragmentFn(device struct MyBuffer &buf ) {
  FragmentOutput f;

  if (uni.iFrame == 0) {
    f.color0 = 0;
    f.color1 = 0;
    return f;
  }

  float4 O = lastFrame[1].read(uint2(thisVertex.where.xy));

  f.color0 = saturate(O);
  f.color0.w = 1;

  // ==========================================================================

  
constexpr sampler chan(coord::normalized, address::clamp_to_edge, filter::linear);
  
#define CS(a)  float2(cos(a),sin(a))
#define rnd(x) ( 2.* fract(456.68*sin(1e4*x+mod(uni.iDate.w,100.))) -1.) // NB: mod(t,1.) for less packed pattern
#define T(U) textureLod(renderInput[0], chan, (U)/uni.iResolution, 0.)

  float2 U = thisVertex.where.xy;

  /*
  if (T(uni.iResolution).x==0.) {
    U = abs(U/uni.iResolution*2.-1.);
    O = float4(max(U.x,U.y)>1.-r/uni.iResolution.y);
    O.w=1.;
    f.color1 = O;
    return f;
  }
  */

  //  float2 M = uni.iMouse.xy; if (length(M)>0.) O += smoothstep(r,0., length(M-U));
  
  for (int i = 0; i < N; i++ ) {
    float4 P = buf.head[i];                            // head state: P, a, t
    if (P.w>0.) {
      O += smoothstep(r,0., length(P.xy-U))  // draw head if active
      *float4(1.-.01*P.w,1,0,1);          // coloring scheme
      // *(.5+.5*sin(6.3*x/N+float4(0,-2.1,2.1,1)));   // coloring scheme
    }
  }
  

  O = saturate(O);
  f.color1 = O;
  return f;
}
