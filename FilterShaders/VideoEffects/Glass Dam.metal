
#define shaderName glass_dam

#include "Common.h" 

struct InputBuffer {
};

initialize() {
//  setTex(0, asset::dancing); // vandamme
//  setTex(1, asset::london);
}

constexpr sampler smp(coord::normalized, address::repeat, mip_filter::linear);

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  const float3 keyColor = float3(0.051,0.639,0.149);
  
  float2 uv = textureCoord;
  float3 colorDelta = tex0.sample(iChannel0, uv).rgb - keyColor.rgb;
  
  float factor = length(colorDelta);
  
  uv += (factor * colorDelta.rb) / 8.0;
  return tex1.sample(smp, uv, level(factor * 1.5) );
}
