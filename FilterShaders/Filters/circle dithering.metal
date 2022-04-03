
#define shaderName circle_dithering

#include "Common.h"

constant const float L = 8.,                   // L*T = neightborhood size
T = 4.,                   // grid step for circle centers
d = 1.;                   // density

#define T(U) tex.sample(iChannel0, (U)/R).r // * 1.4
                                                 //#define T(U) sqrt( texture(iChannel0, (U)/R).r * 1.4 )
                                                 //#define T(U) length(texture(iChannel0, (U)/R).rgb)

#define rnd(P)  fract( sin( dot(P,float2(12.1,31.7)) + 0.*uni.iTime )*43758.5453123)
#define rnd2(P) fract( sin( (P) * float2x2(12.1,-37.4,-17.3,31.7) )*43758.5453123)

#define C(U,P,r) smoothstep(1.5,0.,abs(length(P-U)-r))                       // ring
                                                                             //#define C(U,P,r) exp(-.5*dot(P-U,P-U)/(r*r)) * sin(1.5*TAU*length(P-U)/r) // Gabor

fragmentFn(texture2d<float> tex) {
  float2 R = uni.iResolution.xy;
  //  fragolor += T(U)-fragColor; return;
  float4 fragColor = 1;

  for (float j = -L; j <=L; j++)    // test potential circle centers in a window around U
    for (float i = -L; i <=L; i++) {
      // float2 P = U+float2(i,j);
      float2 P = floor( thisVertex.where.xy/T + float2(i,j) ) *T;          // potential circle center
      P += T*(rnd2(P)-.5);
      float v = T(P),                                // target grey value
      r = mix(2., L*T ,v);                     // target radius
      if ( rnd(P) < (1.-v)/ r*4.*d /L*T*T )          // draw circle with probability
        fragColor -= C(thisVertex.where.xy,P,r)*.2 ; // * (1.-texture(iChannel0, (thisVertex.where.xy)/R)); // colored variant
    }
  // fragColor = sqrt(fragColor);
  return fragColor;
}
