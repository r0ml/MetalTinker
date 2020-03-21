
#define shaderName LaPlace_filter

#include "Common.h" 

struct KBuffer {
  string textures[1];
};

initialize() {
  setTex(0, asset::london);
}

fragmentFn() {
  float2 uv = thisVertex.where.xy / uni.iResolution;

  // float3 cf = texfilter(fc, texture[0]);
  float3 scc = texture[0].sample(iChannel0, uv).rgb;
  float2 sz = textureSize(texture[0]);
  float3 sum = (texture[0].sample( iChannel0, uv + float2(-1,  0) / sz).rgb +
                texture[0].sample( iChannel0, uv + float2( 1,  0) / sz).rgb +
                texture[0].sample( iChannel0, uv + float2( 0, -1) / sz).rgb +
                texture[0].sample( iChannel0, uv + float2( 0,  1) / sz).rgb
                ) - scc * 4.;

  return float4( scc * pow(luminance(sum * 6.), 1.25), 1);
}
