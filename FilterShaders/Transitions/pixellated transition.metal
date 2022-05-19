
#define shaderName pixellated_transition

#include "Common.h" 

struct InputBuffer {
  int3 squares;
};

initialize() {
  in.squares = {10, 16, 25};
}

fragmentFunc(texture2d<float> tex0, texture2d<float> tex1, device InputBuffer& in) {
  float2 uv = textureCoord;

  float2 tc = worldCoordAdjusted / 2.;
  tc = floor(tc * in.squares.y + 0.5) / in.squares.y;  // pixellate
  float mask = length(tc);   // create the circle mask
  mask = mod(mask - scn_frame.time*0.2, 2.0);     // mod the mask so that we get alternating rings
  mask = step(mask, 1.0);     // step the mask to threshold it to black and white
  
    // sample textures and choose mask
  return mix(tex0.sample(iChannel0, uv ), tex1.sample(iChannel0, uv), mask);
  
}



