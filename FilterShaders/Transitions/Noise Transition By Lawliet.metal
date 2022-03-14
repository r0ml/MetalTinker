
#define shaderName noise_transition_by_lawliet

#include "Common.h" 

struct InputBuffer {
};

initialize() {
//  setTex(0, asset::london);
//  setTex(1, asset::flagstones);
}

#define COLOR float4(1.0,0.0,0.0,0.5)
#define SPEED 0.25

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord;
  float4 fore = tex0.sample(iChannel0,uv);
  float4 back = tex1.sample(iChannel0,uv);
  float noise = interporand( floor(thisVertex.where.xy / 5) / uni.iResolution, 256).r; // texture[2].sample(iChannel0,uv * 5.0);

  // float4 light = COLOR;
  float offset = sin(mod(uni.iTime * SPEED,PI * 0.5));
  float a = saturate(offset * 3.0 - uv.x - noise);
  return back * (1.0 - a) + fore * a;
}
