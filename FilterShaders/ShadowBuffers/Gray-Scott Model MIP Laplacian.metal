/** 
 Author: FabriceNeyret2
 revisit [url]https://www.shadertoy.com/view/XtjcWK[/url] using MIPmap to calculate laplacian. More stable -> dt*2.
 You might relate it to Multigrid solvers and to Difference of Gaussians.

 Mouse paint.
 */

// FIXME: not working

#define shaderName Gray_Scott_Model_MIP_Laplacian

#include "Common.h" 
struct KBuffer {  };
initialize() {}

 // directly inspired from https://www.shadertoy.com/view/XtjcWK
 // But using MIPmap to evaluate Laplacian

// float4 T(float z, float2 U, texture2d<float>rendin0) { return rendin0.sample(iChannel0, U, z); }


fragmentFn1() {
  FragmentOutput fff;

  fff.fragColor = texelFetch( renderInput[0], int2(thisVertex.where.xy), 0);
  fff.fragColor.x = 1.-fff.fragColor.x;
  fff.fragColor.w=1;

// ============================================== buffers =============================

  float2 R = uni.iResolution.xy;
  float2 U = thisVertex.where.xy / R;

  float4 C = renderInput[0].sample(iChannel0, U, level(0) ),
  D = 4.5* ( renderInput[0].sample(iChannel0, U, level(.66) ) - C );             // laplacian

  float dt = 2.,
  f = .01 + U.x/13.,
  k = .04 + U.y/35.,
  s = C.x*C.y*C.y;

  C += dt * float4( -s + f*(1.-C.x) + .2*D.x, // Gray-Scott Model + integration
                 s - (f+k)*C.y  + .1*D.y, // http://mrob.com/pub/comp/xmorphia/
                 0, 0 );

  fff.pass1 = length( uni.iMouse.xy * R - U*R ) < 10.
  ? float4(.25,.5,1,0)                // mouse paint
  : C;

  return fff;
}
