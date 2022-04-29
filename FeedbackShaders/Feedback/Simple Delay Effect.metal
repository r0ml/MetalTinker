
#define shaderName simple_delay_effect

#include "Common.h" 

struct KBuffer {
  string textures[1];
};

initialize() {
  setTex(0, asset::diving); // vandamme
}


fragmentFn1() {
  FragmentOutput f;
  const float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  f.fragColor = renderInput[0].sample(iChannel0,uv);
  
  // ============================================== buffers =============================
  
#define DELAY_AMOUNT 0.9
  
  // #define backbuffer(uv) texture(iChannel0,uv)
  // #define texture(uv) texture(iChannel1,uv)
  
  f.pass1 = mix(texture[0].sample(iChannel0,uv), f.fragColor, DELAY_AMOUNT);
  return f;
}
