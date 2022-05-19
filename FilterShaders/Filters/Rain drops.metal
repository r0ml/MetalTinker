
#define shaderName rain_drops

#include "Common.h" 

constexpr sampler smp(coord::normalized, address::repeat, mip_filter::linear);

// #define a(p) textureLod(texture[0], iChannel0, p, 2.5)
// #define t texture[1].sample(iChannel0,

fragmentFunc(texture2d<float> tex) {
  float2 g = textureCoord;
  
  float4 c = tex.sample(iChannel0, g, level(2.5) );
  float2 x = float2(20);
  float3 n = interporand( round(g*x - .3) / x);
  float2 z = g*x * 6.3 + ( rand2( g * .1) - .5) * 2.;
  
  x = sin(z) - fract(scn_frame.time * (n.b + .1) + n.g) * .5;
  if (x.x+x.y-n.r*3. > .5) {
    return tex.sample(smp, g + cos(z) * .2, level(2.5));
  }
  return c;
}

