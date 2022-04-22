
#define shaderName pyramid_op

#include "Common.h"
struct KBuffer {
  int webcam;
};

initialize() {
}

// --- your pyramidal operation here
static float4 op (float4 t00, float4 t10, float4 t01, float4 t11) {
  // return (t00+t10+t01+t11) / 4.;           // average
  return max(max(t00,t10),max(t01,t11));   // max
                                           // return min(min(t00,t10),min(t01,t11));   // min
}

#define T1(d) webcam.sample(iChannel0, U   +d/R)                    // source image
                                                                    //#define T0(d) texture(iChannel0, U-V +d/R)
#define T0(d) renderInput[0].sample(iChannel0, U/(2.-V)-V +d/R*sign(1.-U))  // prev cascade level


fragmentFn1() {
  FragmentOutput f;
  float4 sol = renderInput[0].sample(iChannel0, float2(1));                 // ultimate cascaded value
  
  float2 UU = thisVertex.where.xy / uni.iResolution;
  f.fragColor = renderInput[0].sample(iChannel0, UU );
  
  // --- your normalization operation here
  if (UU.y>UU.x)  f.fragColor /= sol;     // using max
                                          // if (U.y>U.x)  O *= .5/sol;  // using mean
  
  
  
  if (max(UU.x,1.-UU.y)<.1) f.fragColor = renderInput[0].sample(iChannel0, float2(1)); // display measured value
  
  f.fragColor.w = 1;

  // ============================================== buffers =============================

  float2 R = uni.iResolution.xy, I=float2(1,0), V;
  float2 U = thisVertex.where.xy * 2./R;
  V = step(2.,exp2(U));
  f.pass1 = V.x+V.y > 0.
  ? op( T0(I.yy),T0(I),T0(I.yx),T0(I.xx) )   // texture(iChannel0, U-1.);
  : op( T1(I.yy),T1(I),T1(I.yx),T1(I.xx) ) ; // texture(iChannel1, U   )
  return f;
}
