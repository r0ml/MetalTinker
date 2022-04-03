
#define shaderName texture_mip_diff

#include "Common.h" 

constexpr sampler chan(coord::normalized, address::repeat, mip_filter::linear);

fragmentFn(texture2d<float> tex) {
  float2 b = textureCoord;
  float lod = 3.0 + cos( 0.25 * tau*uni.iTime );
  float4 col = 0.5 - 8.0 * (tex.sample(iChannel0, b) -
                            tex.sample(chan, b, level(lod)) );
  return float4(col.rgb, 1);
}

