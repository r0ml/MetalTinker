/** 
 Author: bram
 This renders an image, but bevels its edges.
 It is a little verbose, and is not optimized (uses a lot of branching) but it does do the trick.
 
 TODO: fix that nasty aliasing at the edge between bevels.
 */

#define shaderName image_with_a_bevelled_edge

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}



fragmentFn(texture2d<float> tex) {
  float imh = 0.8 ;
  float imw = imh;
  float imx = float( 1 - imw ) / 2.0 ;
  float imy = float( 1 - imh ) / 2.0 ;
  float2 uv = textureCoord;

  if ( uv.x > imx &&
      uv.x < imx+imw &&
      uv.y > imy &&
      uv.y < imy+imh )
  {
    float4 rgba = tex.sample(iChannel0, uv);
    float x = ( uv.x - imx ) / imw;
    float y = ( uv.y - imy ) / imh;
    float e0 = x;
    float e1 = 1.0-x;
    float e2 = y;
    float e3 = 1.0-y;
    float scl = 1.0;
    if ( e0 <= e1 && e0 <= e2 && e0 <= e3 && e0 < 0.1 )
      scl = 1.2; // left edge
    if ( e1 <= e0 && e1 <= e2 && e1 <= e3 && e1 < 0.1 )
      scl = 0.5; // right edge
    if ( e2 <= e1 && e2 <= e0 && e2 <= e3 && e2 < 0.1 )
      scl = 1.5; // bottom edge
    if ( e3 <= e1 && e3 <= e2 && e3 <= e0 && e3 < 0.1 )
      scl = 0.7; // top edge
    return rgba * scl;
  }
  else
  {
    return float4(0,0,0.5,1);
  }
}
