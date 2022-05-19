
#define shaderName infinite_video

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 u = worldCoordAdjusted / 2;
  return  tex.sample( iChannel0, fract( .2*scn_frame.time - float2(u.x,1)/u.y ) )* -u.y*3. ;
}
