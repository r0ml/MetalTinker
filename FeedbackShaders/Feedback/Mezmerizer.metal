
#define shaderName mezmerizer

#include "Common.h" 

static float4 r(int x, int y, float2 winCoord, texture2d<float> rendin0) {
  return rendin0.read(uint2( int2(winCoord)+int2(x,y)));
}

fragmentFn( texture2d<float> lastFrame ) {
  float4 fragColor = (
                      max(4. - .3*abs(float(int(thisVertex.where.x)/4^int(thisVertex.where.y)/4) - (sin(uni.iTime/4.-3.)+1.) * 128.),0.)
                      + r(64,0 , thisVertex.where.xy, lastFrame)
                      + r(-64,0, thisVertex.where.xy, lastFrame)
                      + r(0,64, thisVertex.where.xy , lastFrame)
                      + r(0,-64, thisVertex.where.xy, lastFrame)
                      )*0.2;
  fragColor.w = 1;
  return fragColor;
}
