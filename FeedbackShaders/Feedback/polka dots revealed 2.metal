
#define shaderName polka_dots_revealed_2

#include "Common.h"

struct KBuffer {  };
initialize() {}


// colored variant of https://www.shadertoy.com/view/MttXRN
// tracker added to a slowed version of https://www.shadertoy.com/view/XldXRN

fragmentFn1() {
  FragmentOutput f;
  f.fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy/uni.iResolution.xy);
  
  // ============================================== buffers =============================
  
  
#define T(x,y) renderInput[0].sample(iChannel0, (thisVertex.where.xy+float2(x,y))/uni.iResolution.rg)
  
  float2 R = uni.iResolution.xy;
  float t = 8.*uni.iTime,
  e = 35./R.y, v;
  
  f.pass1 = float4(1);
  if ( uni.iFrame<10 || ( uni.mouseButtons && all( thisVertex.where.xy-.5==uni.iMouse.xy * uni.iResolution.xy  ) ) )
    f.pass1 = .5+.5*sin(thisVertex.where.x+917.*thisVertex.where.y+float4(0,2,-2,0)), f.pass1.a=1.;        // mark dot with random hue
  
  if ( any(T(0,0) != float4(0)))
    for (int j=-2; j<3; j++)
      for (int i=-2; i<3; i++)
      { float4 c = T(i,j);
        if ( c.a==1. && any(c.rgb!=float3(1)) ) { f.pass1 = c; break; }   // track dot
      }
  
  // ------ code similar to https://www.shadertoy.com/view/XldXRN ------------------------------
  float2 U = ( thisVertex.where.xy+thisVertex.where.xy - R ) /R.y * 8.
  * makeMat(sin(PI/3.*floor(t/2./PI) + PI*float4(.5,1,0,.5)));   // animation ( switch dir )
  
  U.y /= .866;
  U -= .5;
  v = ceil(U.y);
  U.x += .5*v;                                                   // hexagonal tiling
  U.x +=  (1.-cos(t/2.)) * (mod(v,2.)-.5) ;                      // animation ( scissor )
  
  U = 2.*fract(U)-1.;                                            // dots
  U.y *= .866;
  f.pass1 *= smoothstep(e,-e, length(U)-.6);
  
  return f;
}
