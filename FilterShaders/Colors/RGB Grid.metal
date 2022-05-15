
#define shaderName rgb_grid

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 u = 2.*textureCoord;
  return tex.sample(iChannel0,fract(u))*float4(u.x>1.==u.y<1.,u.x>1.,u.y<1.,1);
}
