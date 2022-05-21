
#define shaderName Spine01

#include "Common.h"

struct InputBuffer {
  struct {
    bool image = true;
    bool depth;
    bool faded;
  } source;
};

// initialize() {
// }

fragmentFunc(texture2d<float> image, texture2d<float> depth, device InputBuffer& in) {
  float2 z = textureCoord * nodeAspect * (textureSize(image).y / textureSize(image));

  if (in.source.image) {
    return image.sample(iChannel0, z);
  } else if (in.source.depth) {
    return depth.sample(iChannel0, z);
  } else if (in.source.faded) {
    float4 a = image.sample(iChannel0, z);
    float4 b = depth.sample(iChannel0, z);

    // assuming that the top of the spine is closer than 0.4, and uninteresting things are further than 0.6 ...
    // clipping between 0.4 and 0.6
    float m = saturate( 1 - (b.x - 0.4) * 5 ) ;
    // a.w = saturate( 1 - (b.x - 0.4)/ 0.6 ) ;

    float4 c = mix(0, a, m);

    return c;
  }

  return float4(0.5, 0.6, 0.7, 1);

}

