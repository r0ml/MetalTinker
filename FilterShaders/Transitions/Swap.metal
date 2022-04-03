
#define shaderName swap

#include "Common.h" 

constant const float reflection = .4;
constant const float perspectivex = .2;
constant const float depth = 3.;

constant const float4 black = float4(0.0, 0.0, 0.0, 1.0);
constant const float2 boundMin = float2(0.0, 0.0);
constant const float2 boundMax = float2(1.0, 1.0);

static bool inBounds (float2 p) {
  return all((boundMin < p)) && all((p < boundMax));
}

static float2 project (float2 p) {
  return p * float2(1.0, -1.2) + float2(0.0, -0.02);
}

static float4 bgColor (float2 p, float2 pfr, float2 pto, texture2d<float> vid0, texture2d<float> vid1) {
  float4 c = black;
  pfr = project(pfr);
  if (inBounds(pfr)) {
    c += mix(black, vid0.sample(iChannel0, pfr), reflection * mix(1.0, 0.0, pfr.y));
  }
  pto = project(pto);
  if (inBounds(pto)) {
    c += mix(black, vid1.sample(iChannel0, pto), reflection * mix(1.0, 0.0, pto.y));
  }
  return c;
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float progress = sin(uni.iTime*.5)*.5+.5;
  float2 p = textureCoord;
//  float progress = uni.iMouse.x;

  float2 pfr, pto = float2(-1.);

  float size = mix(1.0, depth, progress);
  float persp = perspectivex * progress;
  pfr = (p + float2(-0.0, -0.5)) * float2(size/(1.0-perspectivex*progress), size/(1.0-size*persp*p.x)) + float2(0.0, 0.5);

  size = mix(1.0, depth, 1.-progress);
  persp = perspectivex * (1.-progress);
  pto = (p + float2(-1.0, -0.5)) * float2(size/(1.0-perspectivex*(1.0-progress)), size/(1.0-size*persp*(0.5-p.x))) + float2(1.0, 0.5);

  bool fromOver = progress < 0.5;

  if (fromOver) {
    if (inBounds(pfr)) {
      return tex0.sample(iChannel0, pfr);
    }
    else if (inBounds(pto)) {
      return tex1.sample(iChannel0, pto);
    }
    else {
      return bgColor(p, pfr, pto, tex0, tex1);
    }
  }
  else {
    if (inBounds(pto)) {
      return tex1.sample(iChannel0, pto);
    }
    else if (inBounds(pfr)) {
      return tex0.sample(iChannel0, pfr);
    }
    else {
      return bgColor(p, pfr, pto, tex0, tex1);
    }
  }
}
