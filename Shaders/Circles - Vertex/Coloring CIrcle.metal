
#define shaderName coloring_circle

#include "Common.h" 
struct InputBuffer {  };
initialize() {}




fragmentFn() {
  float2 r =  worldCoordAspectAdjusted;
  float radius = 0.5;

  float4  color = float4(r,0.1+0.3*sin(uni.iTime),1.0);
  //float4 pixel;
  //if((uv.x*uv.x)+(uv.y*uv.y) < (radius*radius))
  //{
  //  pixel = color;
  //fragColor = pixel;
  float4 white = float4(0.0);
  float4 pixel;
  pixel = white;
  if(length(r) < radius*radius) {
    pixel =  color;
  }

  
  return pixel;
}
