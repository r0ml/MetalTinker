
// FIXME: completely broken

#define shaderName mesh_edit

#include "Common.h"

constant const float Siz = 80.;
// draw segment [a,b]
// #define L(a,b)  O.g+= 2e-1 / length( clamp( dot(U-a,v=b-a)/dot(v,v), 0.,1.) *v - U+a )

static void L(float2 a, float2 b, thread float4& O, const float2 U ) {
  float2 v = b-a;
  O.g+= 0.2 / length( clamp( dot(U-a,v)/dot(v,v), 0.,1.) *v - U+a );
}


#define T(i,j) renderInput[0].sample(iChannel0,(.5+Siz*float2(i,j))/uni.iResolution.xy).xy

fragmentFn1() {
  FragmentOutput f;
  float2 U = thisVertex.where.xy;
  f.fragColor = 0;
  for (int j=0; j< uni.iResolution.y/Siz; j++)
  {
    float2 P00, P01, P10 = T(0,j), P11 = T(0,j+1);
    
    for (int i=0; i<uni.iResolution.x/Siz; i++)
    {
      P00=P10, P01=P11, P10 = T(i+1,j), P11=T(i+1,j+1);
      if (j<9 ) L(P00,P01, f.fragColor, U);   // draw one vertical segment
      if (i<16) L(P00,P10, f.fragColor, U);   // draw one horizontal segment
      f.fragColor += smoothstep(5.,3.,length(U-T(i,j)));  // draw points
    }
  }
  f.fragColor.w = 1;

  
  // each pixel of BufA encodes a pair of vertex coordinates.
  // It's Image shader responsability to pick and connect some of these.
  
  
  //  float2 U = thisVertex.where.xy/uni.iResolution;
  float4 O = renderInput[0].read(uint2(thisVertex.where.xy));
  //if (uni.iFrame==0) {
  if (length(O.xy)==0.) {   // better if further increase of window size
    O.xy = thisVertex.where.xy + 10.*(2.*   rand2(thisVertex.where.xy/uni.iResolution) - 1);
  } else  {
    float a = 10.*uni.iTime + thisVertex.where.x+117.1*thisVertex.where.y; // decorelates rotation angle
    O.xy += .2* float2(cos(a),sin(a));       // shake coords
  
    if ( length(uni.iMouse * uni.iResolution - O.xy) < 10. ) {       // edit coords
      O.xy = uni.iMouse * uni.iResolution;
    }
  }
  f.pass1 = O;
  return f;
}
