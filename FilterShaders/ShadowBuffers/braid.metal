// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#define shaderName braid

#define SHADOWS 2

#include "Common.h"




/* I could go two ways.
 1) pass in the attachments as an array of textures.
 2) run a compute function with an array of texture arguments -- I would have to specify how many threads to run for the compute function.
 3) For many shaders, the usage is to have the previous frame be available for use in computing the new frame.   So another way to go might be to just
    pass in the last frame as an argument for the next frame.  This would be passed in if the fragment shader has a texture argument called "lastFrame"?
    Or always passed in?
 The frame initializer could maybe take an array of control structures -- one for each pipeline pass.
 */

fragmentFn() {
  FragmentOutput f;

//  FragmentOutput f;
//  float2 g = thisVertex.where.xy;
//  g.y = uni.iResolution.y-g.y;
//  f.fragColor = renderInput[0].read(uint2(g));

  // =====================
//  if (uni.iFrame == 0) {
//    return 0;
//  }

  float2 Uz = ( thisVertex.where.xy * 2 - uni.iResolution ) / uni.iResolution.y;

  uint2 z =  uint2(thisVertex.where.xy); // - uint2(0, 1);
  z.y = uni.iResolution.y - z.y;
  float4 Ox = lastFrame[1].read( z );
  float4 Oy = Ox;

  float Rx = uni.iTime/uni.iResolution.y*uni.iResolution.x; // was 360 -- speed of motion

  for(uint i=0;i<3;i++) {
    Rx += 2.1;
    float4 p = float4( 1.4, 1.2, 1, .5*sin(Rx+Rx)+.5 );
    float2 q = float2(.4*cos(Rx), -.7) - Uz;
    float t = length(q) - 0.2;  // 0.2 is the diameter of the glowing circle
    float r = smoothstep(0.1, -0.1, t); // 0.1, -0.1 is the fuzziness of the edge
    float4 V = r * p ;

    if ( V.a > Ox.a ) {
      Ox = V;
    }
  }
//  out[0].write(O, uint2(thisVertex.where.xy));
  f.color0 = Oy;
  f.color1 = saturate(Ox);
  return f;
}

