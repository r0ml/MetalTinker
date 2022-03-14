
#define shaderName its_all_an_illusion

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}


fragmentFn(texture2d<float> tex) {
  constexpr sampler iChannel0(coord::normalized, address::repeat, filter::linear);
  float2 p = textureCoord;
  return min(tex.sample(iChannel0, p+uni.iDate.w*.1), tex.sample(iChannel0, p+uni.iDate.w * .1 - p*length(p)*.1));
}
