
#define shaderName Doom_Screen_Melt

#include "Common.h"
struct InputBuffer {
  float3 START_SPEED;
  float3 MELT_SPEED;
  int3 RESTART_IVAL;
};

initialize() {
  in.START_SPEED = {1, 2.7, 5};
  in.MELT_SPEED = {0.5, 1, 3 };
  in.RESTART_IVAL = {1, 3, 5};
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 p = textureCoord;
  float2 b = p;

  float t = mod(uni.iTime, in.RESTART_IVAL.y);
  // flip textures every second melt
  float rt = mod(uni.iTime, 2. * in.RESTART_IVAL.y);
  bool texFlip = rt > .0 && rt < in.RESTART_IVAL.y;
  
  // first let some "paint" drip before moving entire texture contents
  float d = in.START_SPEED.y * t;
  if(d > 1.) d = 1.;
  
  // initial paint melt shift
  p.y += d * 0.35 * rand(float2(p.x, .0));
  
  // now move entire melted texture offscreen
  if(d == 1.)
    p.y += in.MELT_SPEED.y * (t - d/in.START_SPEED.y );
  
  float4 fragColor;
  
  fragColor = (texFlip ? tex0 : tex1).sample(iChannel0, p);

  // draw second image behind the melting texture
  if(p.y > 1.) {
    fragColor = (texFlip ? tex1 : tex0).sample(iChannel0, b);
  }
  return fragColor;
}


