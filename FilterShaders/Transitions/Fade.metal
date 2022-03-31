
#define shaderName fade

#include "Common.h" 

struct InputBuffer {
  float3 duration;
  float3 intermission;
};

initialize() {
  in.duration = {1.5, 2, 4};
  in.intermission = {0, 2, 4};
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord;

  float tot = 2. * (in.duration.y + in.intermission.y);
  float t = mod(uni.iTime, tot);
  float z = mod(t, in.duration.y + in.intermission.y);
  bool s = t > (in.duration.y + in.intermission.y);
  float m = min(z, in.duration.y) / in.duration.y;
  if (s) { m = s - m; }

  float3 texx0 = tex0.sample(iChannel0, uv).xyz;
  float3 texx1 = tex1.sample(iChannel0, uv).xyz;
  return float4(mix(texx0, texx1, m), 1);
}
