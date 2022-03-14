
#define shaderName Bokeh_disc

#include "Common.h"
struct InputBuffer {
};

initialize() {
//  setTex(0, asset::lichen);
//  setTex(1, asset::stump);
//  setTex(2, asset::lava);
}

// The Golden Angle is (3.-sqrt(5.0))*PI radians
// #define GOLDEN_ANGLE 2.39996

constant const int ITERATIONS = 150;

//-------------------------------------------------------------------------------------------
static float3 Bokeh(texture2d<float> tex, float2 uv, float radius)
{
  float GOLDEN_ANGLE = (3 - sqrt(5.)) * PI;
  
  float3 acc = float3(0), div = acc;
  float r = 1.;
  float2 vangle = float2(0.0,radius*.01 / sqrt(float(ITERATIONS)));

  for (int j = 0; j < ITERATIONS; j++)
  {
    // the approx increase in the scale of sqrt(0, 1, 2, 3...)
    r += 1. / r;
    vangle = rot2d(GOLDEN_ANGLE) * vangle;
    float3 col = tex.sample(iChannel0, uv + (r-1.) * vangle).xyz; /// ... Sample the image
    col = col * col *1.8; // ... Contrast it for better highlights - leave this out elsewhere.
    float3 bokeh = pow(col, float3(4));
    acc += col * bokeh;
    div += bokeh;
  }
  return acc / div;
}

//-------------------------------------------------------------------------------------------

fragmentFn(texture2d<float> tex0, texture2d<float> tex1, texture2d<float> tex2) {
  float2 uv = textureCoord * aspectRatio;

  float time = mod(uni.iTime*.2 +.25, 3.0);

  float rad = .8 - .8*cos(time * TAU);
  if (uni.mouseButtons) {
    rad = (uni.iMouse.x)*3.0;
  }

  if (time < 1.0) {
    return float4(Bokeh(tex0, uv, rad), 1.0);
  } else if (time < 2.0) {
    return float4(Bokeh(tex1, uv, rad), 1.0);
  } else {
    return float4(Bokeh(tex2, uv, rad), 1.0);
  }

}
