
#define shaderName correct_video_aspect_ratio

#include "Common.h"
struct InputBuffer {
};

initialize() {
}






fragmentFn(texture2d<float> tex) {
  float2 margin = float2(10),
  Sres = uni.iResolution.xy -2.*margin,
  Tres = textureSize(tex),
  ratio = Sres/Tres;
  
  float2 U = thisVertex.where.xy - margin;
  
  // centering the blank part in case of rectangle fit
  U -= .5*Tres*max(float2(ratio.x-ratio.y,ratio.y-ratio.x),0.);
  
  //U /= Tres*ratio.y;               // fit height, keep ratio
  //U /= Tres*ratio.x;               // fit width, keep ratio
  U /= Tres*min(ratio.x,ratio.y);  // fit rectangle,  keep ratio
  U *= 1.;                         // zoom out factor
  
  return all(fract(U)==U)
  ? tex.sample(iChannel0, U)
  : 0;
}
