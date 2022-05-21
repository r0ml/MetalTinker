
#define shaderName cosine_jamming

#include "Common.h"

struct InputBuffer {
  float3 smoothness;
};

initialize() {
  in.smoothness = {0.1, 0.2, 0.4};
}

fragmentFunc(device InputBuffer &in) {
  float2 uv = worldCoordAdjusted;
  float2 mouse = (2 * mouse - 1) * nodeAspect;
  uv*=10.;
  mouse*=10.;

  float col= 0.5 + cos(length(uv)*2)/2;
  float col2=0.5 + cos(length(uv-mouse)*2)/2;

  return float4(smoothstep(1-in.smoothness.y, 1+in.smoothness.y, col + col2));
}
