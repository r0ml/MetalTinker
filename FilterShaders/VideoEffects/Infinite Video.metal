
#define shaderName infinite_video

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 u = worldCoordAspectAdjusted / 2;
  return  tex.sample( iChannel0, fract( .2*uni.iTime - float2(u.x,1)/u.y ) )* -u.y*3. ;
}
