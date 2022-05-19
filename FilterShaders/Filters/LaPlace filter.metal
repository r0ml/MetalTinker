
#define shaderName LaPlace_filter

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 uv = textureCoord;

  // float3 cf = texfilter(fc, in.inputTexture);
  float3 scc = tex.sample(iChannel0, uv).rgb;
  float2 sz = textureSize(tex);
  float3 sum = (tex.sample( iChannel0, uv + float2(-1,  0) / sz).rgb +
                tex.sample( iChannel0, uv + float2( 1,  0) / sz).rgb +
                tex.sample( iChannel0, uv + float2( 0, -1) / sz).rgb +
                tex.sample( iChannel0, uv + float2( 0,  1) / sz).rgb
                ) - scc * 4.;

  return float4( scc * pow(luminance(sum * 6.), 1.25), 1);
}
