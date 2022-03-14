
#define shaderName Doom_Screen_Melt

#include "Common.h"
struct InputBuffer {
};

initialize() {
//  setTex(0, asset::london);
//  setTex(1, asset::bubbles);
}

 


// ----------------------------------------------------
//  "Doom Screen Melt" by Krzysztof Kondrak @k_kondrak
// ----------------------------------------------------

// initial "paint melt" speed
constant const float START_SPEED  = 2.7;
// texture melting off screen speed
constant const float MELT_SPEED   = 1.;
// melt effect restart interval (seconds)
constant const float RESTART_IVAL = 3.;

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 p = textureCoord;
  float2 b = p;

  float t = mod(uni.iTime, RESTART_IVAL);
  // flip textures every second melt
  float rt = mod(uni.iTime, 2. * RESTART_IVAL);
  bool texFlip = rt > .0 && rt < RESTART_IVAL;
  
  // first let some "paint" drip before moving entire texture contents
  float d = START_SPEED * t;
  if(d > 1.) d = 1.;
  
  // initial paint melt shift
  p.y += d * 0.35 * rand(float2(p.x, .0));
  
  // now move entire melted texture offscreen
  if(d == 1.)
    p.y += MELT_SPEED * (t - d/START_SPEED);
  
  float4 fragColor;
  
  if(texFlip) {
    fragColor = tex0.sample(iChannel0, p);
  } else {
    fragColor = tex1.sample(iChannel0, p);
  }

  // draw second image behind the melting texture
  if(p.y > 1.) {
    if(texFlip) {
      fragColor = tex1.sample(iChannel0, b);
    } else {
      fragColor = tex0.sample(iChannel0, b);
    }
  }
  return fragColor;
}


