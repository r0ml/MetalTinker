
#define shaderName cheap_outline_and_cartoon_effect

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

#define OUTLINE_COLOR float4(.2)
#define OUTLINE_STRENGTH 20.
#define OUTLINE_BIAS -.5
#define OUTLINE_POWER 1.

#define PRECISION 6.

fragmentFn(texture2d<float> tex) {
  float2 r = uni.iResolution.xy;
  float4 p = gammaDecode(tex.sample(iChannel0,thisVertex.where.xy/r)),
  s = gammaDecode(tex.sample(iChannel0,(thisVertex.where.xy+.5)/r));
  float l = saturate(pow(length(p-s),OUTLINE_POWER)*OUTLINE_STRENGTH+OUTLINE_BIAS);
  p = floor( gammaEncode(p)*(PRECISION+.999))/PRECISION;
  return mix(p,OUTLINE_COLOR,l);
}
