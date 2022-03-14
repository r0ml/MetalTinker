
#define shaderName histogram_preserving_distortion

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

static float turb(  float2 uv ) {
  float f = 0.0;

  float2x2 m = float2x2( 1.6,  1.2, -1.2,  1.6 );
  f  = 0.5000*(2 * noisePerlin( uv ) - 1); uv = m*uv;
  f += 0.2500*(2 * noisePerlin( uv ) - 1); uv = m*uv;
  f += 0.1250*(2 * noisePerlin( uv ) - 1); uv = m*uv;
  f += 0.0625*(2 * noisePerlin( uv ) - 1); uv = m*uv;
  return f;
}
// -----------------------------------------------


fragmentFn(texture2d<float> tex) {
  constexpr sampler chan(coord::normalized, address::repeat, filter::linear, mip_filter::nearest);
  float2 uv = textureCoord,
  m = uni.iMouse.xy ;
  if (!uni.mouseButtons) m = float2(.5);

  float f;
  //f =  noise( 16.*uv );
  f = turb(m.x*uv);
  // O = float4(.5 + .5* f);

  uv += 64.*float2(-dfdy(f),dfdx(f)) * m.y;
  float lvl = 6 * (uv.x > 0.9);
  return tex.sample(chan, uv, level(lvl) );
}
