
#define shaderName Gaussian_blur

#include "Common.h"

struct InputBuffer {
  float3 radius;
  float3 sigma;
  bool gaussian;
  bool edge;
};

initialize() {
  in.radius = {3, 6, 15};
  in.sigma = {1, 2.8, 5};
}

fragmentFn(texture2d<float> tex) {
  float2 b = thisVertex.texCoords;
  float4 original = tex.sample(iChannel0, b);

  float2 res = textureSize(tex);
  float sigma = in.sigma.y;
  float radius = in.radius.y;
  float4 color = 0;
  float tss = 2 * sigma * sigma;
  float pss = 1 / (PI * tss);

  float wsum = 0.0;
  for (int ry = -radius; ry <= radius; ++ry) {
    for (int rx = -radius; rx <=radius; ++rx) {
      float w = pow(pss * exp(-  length_squared(float2(rx, ry)  ) / tss), float(in.gaussian));
      wsum += w;
      color += tex.sample(iChannel0, b+float2(rx,ry)/res)*w;
    }
  }
  float3 blurred = color.rgb/wsum;
  return float4(abs(blurred - in.edge * original.rgb), 1);
}
