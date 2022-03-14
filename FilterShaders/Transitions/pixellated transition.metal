
#define shaderName pixellated_transition

#include "Common.h" 
struct InputBuffer {
};

initialize() {
//  setTex(0, asset::wood);
//  setTex(1, asset::london);
}

 


constant const float squares = 16.0;
// constant const float amt = 0.1;

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord;

  float2 tc = worldCoordAspectAdjusted / 2.;
  tc = floor(tc * squares + 0.5) / squares;  // pixellate
  float mask = length(tc);   // create the circle mask
  mask = mod(mask - uni.iTime*0.2, 2.0);     // mod the mask so that we get alternating rings
  mask = step(mask, 1.0);     // step the mask to threshold it to black and white
  
    // sample textures and choose mask
  return mix(tex0.sample(iChannel0, uv ), tex1.sample(iChannel0, uv), mask);
  
}



