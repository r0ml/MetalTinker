
#define shaderName emboss_video_texture

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float4 fragColor = tex.sample(iChannel0, textureCoord);
  fragColor += .5+15.*dfdy(length(fragColor)) - fragColor;
  fragColor *= float4(1,.8,.2,1);
  return fragColor;
}
