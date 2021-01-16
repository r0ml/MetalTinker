
// MAPPED

#define shaderName Breathing_Exercise

#include "Common.h"
struct InputBuffer {  };
initialize() {}

static constant float4 colors[3] = {
  float4(.4, .6, 1, 1),
  float4(.35, .55, .95, 1),
  float4(1)
};


fragmentFn() {
  float len = length( worldCoordAspectAdjusted ) ;
  float t = uni.iTime * .5;
  uint zone = (len < .1 + .3 * abs(sin(t))) + (len < .5 + .1 * abs(cos(t)));
  return colors[zone];
}


