
#define shaderName polka_dots_revealed

#include "Common.h"

struct KBuffer {  };
initialize() {}


// tracker added to a slowed version of https://www.shadertoy.com/view/XldXRN
// colored variant : https://www.shadertoy.com/view/MlcSz7


fragmentFn1() {
  FragmentOutput f;
  f.fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy/uni.iResolution.xy);
  // ============================================== buffers =============================
  
  float4 red = float4(1,0,0,1);
  
#define T(x,y) renderInput[0].sample(iChannel0, (thisVertex.where.xy+float2(x,y))/uni.iResolution.rg)
  
  f.pass1 = float4(1);
  if (   (uni.iFrame<10 && all(thisVertex.where.xy-.5==uni.iResolution.xy/2.) )
      || ( uni.mouseButtons && all(thisVertex.where.xy-.5==uni.iMouse.xy * uni.iResolution.xy ) )     ) f.pass1 = red;       // mark dot
  if ( all(T(0,0)!=float4(0)))
    for (int j=-2; j<3; j++)
      for (int i=-2; i<3; i++)
        if ( all(T(i,j)==red) ) { f.pass1 = red; break; }               // track dot
  
  // ------ code similar to https://www.shadertoy.com/view/XldXRN ------------------------------
  float2 R = uni.iResolution.xy;
  float2 U = ( thisVertex.where.xy+thisVertex.where.xy - R ) /R.y * 8.;
  
  float t = 8.*uni.iTime,
  e = 35./R.y, v;
  //       a = PI/3.*floor(t/2./PI);
  //U *= float2x2(cos(a),-sin(a), sin(a), cos(a));
  U *= makeMat(sin(PI/3.*floor(t/2./PI) + PI*float4(.5,1,0,.5)));     // animation ( switch dir )
  
  U.y /= .866;
  U -= .5;
  v = ceil(U.y);
  U.x += .5*v;                                                   // hexagonal tiling
                                                                 //U.x += sin(t) > 0. ? (.5-.5*cos(t)) * (2.*mod(v,2.)-1.) : 0.;
  U.x +=  (1.-cos(t/2.)) * (mod(v,2.)-.5) ;                      // animation ( scissor )
                                                                 //U.x += (1.-cos(t/2.)) * (mod(v,2.)-.5);                        // variant
  
  U = 2.*fract(U)-1.;                                            // dots
  U.y *= .866;
  f.pass1 *= smoothstep(e,-e, length(U)-.6);
  
  return f;
}
