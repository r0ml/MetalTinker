
#define shaderName Procedural_Normal_Map

#include "Common.h"
struct InputBuffer {
  bool lighting;
  bool specular;
};

initialize() {
  in.lighting = true;
  in.specular = true;
}

#define OFFSET_X 1
#define OFFSET_Y 1
#define DEPTH	 7.5

static float3 texsample(const float2 xy, float2 uv, texture2d<float> tex0) {
  uv = uv + xy / textureSize(tex0);
  return tex0.sample(iChannel0, uv).xyz;
}

static float3 normal(const float2 winCoord, texture2d<float> tex0) {
  float R = abs(luminance(texsample( float2(OFFSET_X,0), winCoord, tex0)));
  float L = abs(luminance(texsample( float2(-OFFSET_X,0), winCoord, tex0)));
  float D = abs(luminance(texsample( float2(0, OFFSET_Y), winCoord, tex0)));
  float U = abs(luminance(texsample( float2(0,-OFFSET_Y), winCoord, tex0)));

  float X = (L-R) * .5;
  float Y = (U-D) * .5;

  return normalize(float3(X, Y, 1. / DEPTH));
}

fragmentFn(texture2d<float> tex) {
  float3 n = normal(textureCoord, tex);

  float3 c = 0;
  if (in.lighting) {
    float3 lp = float3(uni.iMouse.xy * uni.iResolution * textureSize(tex), 200.);
    float3 sp = float3(thisVertex.where.xy * textureSize(tex), 0.);

    c = texsample(0, textureCoord, tex) * dot(n, normalize(lp - sp));

    if (in.specular) {
      float e = 64.;
      float3 ep = float3(textureSize(tex).x * .5, (textureSize(tex).y) * .5, 500.);
      c += pow(saturate(dot(normalize(reflect(lp - sp, n)),
                            normalize(sp - ep))), e);
    }
  } else {

    c = n;
  }

  return float4(c, 1);
}
