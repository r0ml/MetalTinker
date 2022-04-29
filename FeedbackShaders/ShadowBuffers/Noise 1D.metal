/** 
 Author: EvilRyu
 ......
 */

// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define shaderName noise_1d

#include "Common.h" 

struct KBuffer {
};
initialize() {}

fragmentFn1() {
  FragmentOutput fff;


  float2 p1 = (-uni.iResolution.xy + 2.0*thisVertex.where.xy)/uni.iResolution.y;
  p1.x+=2.3;
  fff.fragColor=renderInput[0].sample(iChannel0,float2(0.9/length(p1),atan2(p1.y,p1.x)+0.5));

// ============================================== buffers =============================

  float2 p = p1 * 2.0;
  float d = sqrt(p.x*p.x+p.y*p.y);
  d=abs(noisePerlin( float2(p.x*1.5+2.0*uni.iTime))-p.y-1.5);
  d=smoothstep(0.1,0.24,d);
  fff.pass1 = float4(d,d,d,1.0);
  return fff;
}

