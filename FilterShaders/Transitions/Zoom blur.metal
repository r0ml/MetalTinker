
#define shaderName zoom_blur

#include "Common.h" 

struct InputBuffer {
  float3 strength;
};

initialize() {
  in.strength = {0.1, 0.3, 1};
}

static float Linear_ease(float begin, float change, float duration, float time) {
  return change * time / duration + begin;
}

static float Exponential_easeInOut(float begin, float change, float duration, float time) {
  if (time == 0.0)
    return begin;
  else if (time == duration)
    return begin + change;
  time = time / (duration / 2.0);
  if (time < 1.0)
    return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
  return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
}

static float Sinusoidal_easeInOut( float begin,  float change,  float duration,  float time) {
  return -change / 2.0 * (cospi( time / duration) - 1.0) + begin;
}

static float3 crossFade( float2 uv, float dissolve, texture2d<float> tex0, texture2d<float> tex1) {
  constexpr sampler smplr(coord::normalized, address::repeat, mip_filter::nearest);
  return mix(tex0.sample(smplr, uv).rgb, tex1.sample(smplr, uv).rgb, dissolve);
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 texCoord = textureCoord;
  float progress = sin(uni.iTime*0.5) * 0.5 + 0.5;
  // Linear interpolate center across center half of the image
  float2 center = float2(Linear_ease(0.5, 0.0, 1.0, progress),0.5);
  float dissolve = Exponential_easeInOut(0.0, 1.0, 1.0, progress);
  
  // Mirrored sinusoidal loop. 0->strength then strength->0
  float strength = Sinusoidal_easeInOut(0.0, in.strength.y, 0.5, progress);
  
  float3 color = float3(0.0);
  float total = 0.0;
  float2 toCenter = center - texCoord;
  
  // randomize the lookup values to hide the fixed number of samples
  float offset = rand(thisVertex.where.xy)*0.5;
  
  for (float t = 0.0; t <= 20.0; t++) {
    float percent = (t + offset) / 20.0;
    float weight = 1.0 * (percent - percent * percent);
    color += crossFade(texCoord + toCenter * percent * strength, dissolve, tex0, tex1) * weight;
    total += weight;
  }
  
  return float4(color / total, 1.0);
}


