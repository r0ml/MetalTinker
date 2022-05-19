
#define shaderName dotty_video

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  return step(length(fract(thisVertex.where.xy*.1)*2.-1.), tex.sample(iChannel0, textureCoord));   // col
}


