
// The texture() call accepts a mip level offset as an optional parameter, which
// allows one to sample from different LODs of the texture. Besides being handy in
// some special situations, it also allows you to fake (box) blur of textures without
// having to perform a blur youtself. This has been traditionally used in demos and
// games to fake deph ot field and other similar effects in a very cheap way.

#define shaderName texture_lod

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;

  float lod = (1 + sin( uni.iTime ))*3 *step( uv.x, 0.5 );
  constexpr sampler chan(coord::normalized, address::repeat, filter::linear, mip_filter::linear);

  float3 col = tex.sample( chan, uv, level(lod) ).xyz;

  return float4( col, 1.0 );
}
