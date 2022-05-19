
#define shaderName Procedural_Noise_Fade

#include "Common.h"

static float noise(const float2 p)
{
  return noisePerlin(p/32.) * 0.58 +
  noisePerlin(p/16.) * 0.2  +
  noisePerlin(p/8.)  * 0.1  +
  noisePerlin(p/4.)  * 0.05 +
  noisePerlin(p/2.)  * 0.02 +
  noisePerlin(p)     * 0.0125;
}

fragmentFunc(texture2d<float> tex) {
  float2 uv = textureCoord;
  float t = abs(sin(scn_frame.time));
  
  // fade to black
  return mix(tex.sample(iChannel0, uv), float4(0), smoothstep(t + .1, t - .1, noise(thisVertex.where.xy * .4)));
}
