// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#define shaderName braid

#include "Common.h"

struct InputBuffer {

};

initialize() {

}

/* I could go two ways.
 1) pass in the attachments as an array of textures.
 2) run a compute function with an array of texture arguments -- I would have to specify how many threads to run for the compute function.

 The frame initializer could maybe take an array of control structures -- one for each pipeline pass.
 */

fragmentFn( array<texture2d<float>, 1> out ) {

//  FragmentOutput f;
//  float2 g = thisVertex.where.xy;
//  g.y = uni.iResolution.y-g.y;
//  f.fragColor = renderInput[0].read(uint2(g));

  // =====================

  float2 U = ( thisVertex.where.xy * 2 - uni.iResolution ) / uni.iResolution.y;
//  float4 Ox = renderInput[0].read( uint2(thisVertex.where.xy) - uint2(0,1) );
  uint2 z =  uint2(thisVertex.where.xy) - uint2(0, 1);
  float4 O = out[0].read( z );
  float2 R = uni.iTime/uni.iResolution.yy*360; // was 360

  for(uint i=0;i<3;i++) {
    R.x += 2.1;
    float4 V = smoothstep(.1,-.1,length( float2(.4*cos(R.x), -.7) - U ) - .2 ) * float4( 1.4, 1.2, 1,  (.5*sin(R+R)+.5).x );
    if (V.a > O.a) {
      O = V.a * float4(V.rgb,1);
    }
  }
  out[0].write(O, uint2(thisVertex.where.xy));
  return O;
}

