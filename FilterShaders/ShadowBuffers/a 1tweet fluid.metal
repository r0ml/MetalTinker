
#define shaderName a_1tweet_fluid
#define SHADOWS 2

#include "Common.h"

struct InputBuffer {
    struct {
      int _1;
      int _2;
      int _3;
    } variant;
};

initialize() {
  in.variant._1 = 1;
}


constexpr sampler chan(coord::normalized, address::clamp_to_edge, filter::linear);

fragmentFn() {
  FragmentOutput f;

  float4 fragColor = 0;
  if (in.variant._1) {
    float2 s = sin( lastFrame[1].read(uint2(thisVertex.where.xy)).xy*5.);
    fragColor = length(fwidth(s));
  } else if (in.variant._2) {
    fragColor=fract( lastFrame[1].read(uint2(thisVertex.where.xy)) );
  } else if (in.variant._3) {
    fragColor=lastFrame[1].read(uint2(thisVertex.where.xy));
  } else {
    fragColor.r = 1;
  }
  fragColor.w = 1;

  // ============================================== buffers =============================

// try bigger numbers than 40 in line 15 for bigger vortices

  
  // -1 char: 11 is roughly 1.75pi so perfect -pi/4 substitute (instead of 1.6)
  // -9 char: if S is chosen wisely the the difference between x and y is roughly (n+.5)*pi
  
  // #define L(b) for(float a=0.;a<5.;a++) { b=sin((uni.iTime+a)/.1+S);
  
  // -8 char: still works but less quality
  //#define L(b) for(float a=0.;a<5.;a++) { b=sin(a/.1+S);
  
  // fragmentFn() {
  // magic numbers: S.x-S.y must be roughly (n+.5)*pi, so we can use it as phase shift above

  float2 winCoord = thisVertex.where.xy;
  float4 pass1 = 0;

  if (in.variant._1) {
    float2 v = 0,S=float2(27,-28);
    for(float a=0.;a<5.;a++) {
      float2 p=sin(fmod( (uni.iTime+a)/.1+S, TAU));
      for(float a=0.;a<5.;a++) {
        float2 q=sin( fmod( (uni.iTime+a)/.1+S, TAU) );
        float2 pqs = (p+q).yx * S;
        v+=p*dot(lastFrame[1].sample(chan,(winCoord+pqs)/uni.iResolution.xy).xy,q);
      }
    }


    float2 out = lastFrame[1].sample(chan, (winCoord+v)/uni.iResolution).xy+.1/(winCoord-1.);
    pass1 = float4(out, 0, 1);
  } else if (in.variant._2) {
    float2 p,q,S=float2(-24,31),v=p=q=S-S;
    
    for(float2 a=S;a.x<-6.;p=sin(a++)) {
      for(float2 a=S;a.x<-6.;q=sin(a++)) {
        float2 ff = lastFrame[1].sample(iChannel0,(((p+q).yx*S+winCoord))/uni.iResolution.xy).xy;
        v+=p*dot(ff,q);
      }
    }
    float2 vv = lastFrame[1].sample(iChannel0,((v+winCoord))/uni.iResolution.xy).xy;
    pass1.xy=vv+.02/(winCoord-1.);
    pass1.zw = 0;
  } else if (in.variant._3) {
    // also working:
    // float2(5,-6) should be a bit faster, but different look
    // float2(15,-18) with a.y<0. in L - gives bigger vortices but > 280 chars
    float2 S=float2(4,-7),p,q,v=p=q=S-S;
    for(float2 a=S;a.y<9.;p=sin(a++)) {
      for(float2 a=S;a.y<9.;q=sin(a++)) {
        float2 ff = lastFrame[1].read(uint2(winCoord+(p+q).yx * S)).xy;
        v+=p*dot(ff,q);
      }
    }
    pass1.xy = lastFrame[1].read(uint2(winCoord+v)).xy+.3/winCoord;
    pass1.zw = 0;
  }
  
  f.color1 = pass1;
  f.color0 = fragColor;
  return f;
}
