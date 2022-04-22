/** 
 Author: TekF
 Paint!

 Draw with the mouse, palette on the left side.
 */

#define shaderName paint

#include "Common.h" 

struct KBuffer {
};
initialize() {}

 
fragmentFn1() {
  FragmentOutput fff;

  fff.fragColor = 1.-texelFetch(renderInput[0], int2(thisVertex.where.xy) ,0);
  fff.fragColor.w = 1;

// ============================================== buffers =============================

// #define T(u) texelFetch(iChannel0,int2(u),0)

  fff.pass1 = texelFetch(renderInput[0], int2(thisVertex.where.xy), 0);

  fff.pass1 = thisVertex.where.x+thisVertex.where.y > 1. ?
  thisVertex.where.x < 32. ?
  step(.5,fract(thisVertex.where.y/float4(64,128,256,1)))
  :
  mix( texelFetch(renderInput[0], int2(0), 0), fff.pass1, min(1.,length(thisVertex.where.xy-uni.iMouse.xy * uni.iResolution)/8.))
  :
  uni.iMouse.x * uni.iResolution.x < 32. ?
  texelFetch(renderInput[0], int2(uni.iMouse.xy * uni.iResolution), 0)
  :
  fff.pass1;

  return fff;
}
