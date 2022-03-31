
#define shaderName cheap_outline_and_cartoon_effect

#include "Common.h"
struct InputBuffer {
  int3 outline_strength;
  float3 outline_bias;
  float3 outline_power;
  float3 precision;
  float4 outline_color;
};

initialize() {
  in.outline_strength = {5, 20, 100};
  in.outline_bias = { -2, -0.5, 2};
  in.outline_power = { 0.5, 1, 3};
  in.outline_color = {0.2, 0.2, 0.2, 1};
  in.precision = {2, 6, 10};
}


#define PRECISION 6.

fragmentFn(texture2d<float> tex) {
  float2 r = uni.iResolution.xy;
  float4 p = gammaDecode(tex.sample(iChannel0,thisVertex.where.xy/r)),
  s = gammaDecode(tex.sample(iChannel0,(thisVertex.where.xy+.5)/r));
  float l = saturate(pow(length(p-s),in.outline_power.y) * in.outline_strength.y + in.outline_bias.y);
  p = floor( gammaEncode(p)*(in.precision.y+.999))/in.precision.y;
  return mix(p, in.outline_color.y, l);
}
