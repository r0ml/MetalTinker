
#define shaderName transition_fade

#include "Common.h" 

struct InputBuffer {
  bool ENABLE_SCROLLING = true; // Enable uv scrolling
};

initialize() {
  //  setTex(0, asset::rust);
  //  setTex(1, asset::flagstones);
}

constant const float T_TRAN = 2.;	// Transition time
constant const float T_INTR = 2.;	// Intermission between in/out
constant const float T_PADN = 2.;	// Padding time at the end of out.
constant const float T_TOTL = ((2. * T_TRAN) + T_INTR + T_PADN);

static float3 transition(float3 tex0, float3 tex1, float t)
{
  return mix(tex0, tex1, t);
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord;
  
  if ( in.ENABLE_SCROLLING ) {
    uv += float2(sin(uni.iTime * .6) * .1, cos(uni.iTime * .1));
  } // ENABLE_SCROLLING
  
  float t = mod(uni.iTime, T_TOTL);
  
  float ts0 =       T_TRAN;
  float ts1 = ts0 + T_INTR;
  float ts2 = ts1 + T_TRAN;
  
  if      (t < ts0) t = t / ts0;                       // Transition A
  else if (t < ts1) t = 1.;                            // Intermission
  else if (t < ts2) t = 1. - ((t - ts1) / (ts2-ts1));  // Transition B
  else              t = 0.;                            // Padding
  
  float3 texx0 = tex0.sample(iChannel0, uv).xyz;
  float3 texx1 = tex1.sample(iChannel0, uv).xyz;
  float3 r = transition(texx0, texx1, t);
  return float4(r, 1);
}
