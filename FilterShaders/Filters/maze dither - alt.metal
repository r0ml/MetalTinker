
#define shaderName maze_dither_alt

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 U = thisVertex.where.xy + ( 8.*fwidth(tex.sample(iChannel0, thisVertex.where.xy / uni.iResolution.xy).r) -.5) ;
  //U += 8.*length(fwidth(texture(iChannel0, U / uni.iResolution.xy))) -.5;  // variants
  //U += floor(16.*length(fwidth(texture(iChannel0, U / uni.iResolution.xy)))) -.5;
  return .1/ fract(   sin(1e5*length (ceil(U/=2.))) < 0.  ? U.x : U.y );
}
