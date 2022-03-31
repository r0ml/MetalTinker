
#define shaderName iron_ondulation

#include "Common.h" 

struct InputBuffer {
    float3 knob1;
    float3 knob2;
    float3 knob3;
};

initialize() {
  in.knob1 = {0.001, 0.05, 0.2};
  in.knob2 = {0.001, 0.05, 0.2};
  in.knob3 = {0.001, 0.05, 0.2};
}

// static constexpr sampler chan(coord::normalized, address::repeat, filter::linear, mip_filter::nearest);

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float2 xy = uv * in.knob1.y + 2 * interporand( thisVertex.where.xy / 10 / uni.iResolution + uni.iTime * in.knob2.y, 128 ).rg - 1;
  return tex.sample(iChannel0, uv - cos(xy) * in.knob3.y);
}

