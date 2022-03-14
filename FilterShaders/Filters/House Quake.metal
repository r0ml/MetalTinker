
// FIXME: do this as a vertex shader?

#define shaderName House_Quake

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

namespace shaderName {

#define octaves 3
  float fbm(const float2 p)
  {
    float value = 0.0;
    float freq = 1.13;
    float amp = 0.57;
    for (int i = 0; i < octaves; i++)
    {
      value += amp * (noisePerlin((p - float2(1.0)) * freq));
      freq *= 1.61;
      amp *= 0.47;
    }
    return value;
  }

  float pat(const float2 p, float timex) {
    float time = timex*0.75;
    float2 aPos = float2(sin(time * 0.035), sin(time * 0.05)) * 3.;
    float2 aScale = float2(3.25);
    float a = fbm(p * aScale + aPos);
    float2 bPos = float2(sin(time * 0.09), sin(time * 0.11)) * 1.2;
    float2 bScale = float2(0.75);
    float b = fbm((p + a) * bScale + bPos);
    float2 cPos = float2(-0.6, -0.5) + float2(sin(-time * 0.01), sin(time * 0.1)) * 1.9;
    float2 cScale = float2(1.25);
    float c = fbm((p + b) * cScale + cPos);
    return c;
  }

  float2 Shake(float maxshake, float mag, float timex)
  {
    float speed = 20.0*mag;
    float shakescale = maxshake * mag;
    
    float time = timex*speed;			// speed of shake
    
    float2 p1 = float2(0.25,0.25);
    float2 p2 = float2(0.75,0.75);
    p1 += time;
    p2 += time;
    
    // random shake is just too violent...
    //float val1 = random(p1);
    //float val2 = random(p2);
    
    float val1 = pat(p1, timex);
    float val2 = pat(p2, timex);
    val1 = saturate(val1);
    val2 = saturate(val2);
    
    return float2(val1*shakescale,val2*shakescale);
  }
}

using namespace shaderName;

fragmentFn(texture2d<float> tex) {
  float maxshake = 0.05;				// max shake amount
  float mag = 0.5+sin(uni.iTime)*0.5;		// shake magnitude...

  // *temp* , We will calc shakexy once in the vertex shader...
  float2 shakexy = Shake(maxshake,mag, uni.iTime);

  float2 uv = textureCoord;

  uv *= 1.0-(maxshake*mag);
  float3 col = tex.sample(iChannel0, uv + shakexy).xyz;

  return float4(col, 1.0);
}
