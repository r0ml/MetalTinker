
#define shaderName Gaussian_blur

#include "Common.h"

struct KBuffer {
  string textures[1];
  struct {
    float3 radius;
    float3 sigma;
    bool gaussian;
    bool edge;
  } options;
};

initialize() {
  setTex(0, asset::london);
  kbuff.options.radius = {3, 6, 15};
  kbuff.options.sigma = {1, 2.8, 5};
}

fragmentFn() {
  float4 original = texture[0].sample(iChannel0, thisVertex.barrio.xy);

  float2 res = textureSize(texture[0]);
  float sigma = kbuff.options.sigma.y;
  float radius = kbuff.options.radius.y;
  float4 color = 0;
  float tss = 2 * sigma * sigma;
  float pss = 1 / (PI * tss);

  float wsum = 0.0;
  for (int ry = -radius; ry <= radius; ++ry) {
    for (int rx = -radius; rx <=radius; ++rx) {
      float w = pow(pss * exp(-  length_squared(float2(rx, ry)  ) / tss), float(kbuff.options.gaussian));
      wsum += w;
      color += texture[0].sample(iChannel0, thisVertex.barrio.xy+float2(rx,ry)/res)*w;
    }
  }
  float3 blurred = color.rgb/wsum;
  return float4(abs(blurred - kbuff.options.edge * original.rgb), 1);
}
