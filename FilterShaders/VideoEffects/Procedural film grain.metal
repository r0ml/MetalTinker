/** 
 Author: luluco250
 Nice and smooth.
 
 
 */
#define shaderName Procedural_film_grain

#include "Common.h"

struct InputBuffer {
};

initialize() {
}




// Feel free to steal this :^)
// Consider it MIT licensed, you can link to this page if you want to.

#define SHOW_NOISE 0
#define SRGB 0
// 0: Addition, 1: Screen, 2: Overlay, 3: Soft Light, 4: Lighten-Only
#define BLEND_MODE 0
#define SPEED 2.0
#define INTENSITY 0.075
// What gray level noise should tend to.
#define MEAN 0.0
// Controls the contrast/variance of noise.
#define VARIANCE 0.5

static float3 channel_mix(float3 a, float3 b, float3 w) {
  return float3(mix(a.r, b.r, w.r), mix(a.g, b.g, w.g), mix(a.b, b.b, w.b));
}

static float gaussian(float z, float u, float o) {
  return (1.0 / (o * sqrt(TAU))) * exp(-(((z - u) * (z - u)) / (2.0 * (o * o))));
}

static float3 madd(float3 a, float3 b, float w) {
  return a + a * b * w;
}

static float3 screen(float3 a, float3 b, float w) {
  return mix(a, float3(1.0) - (float3(1.0) - a) * (float3(1.0) - b), w);
}

static float3 overlay(float3 a, float3 b, float w) {
  return mix(a, channel_mix(
                            2.0 * a * b,
                            float3(1.0) - 2.0 * (float3(1.0) - a) * (float3(1.0) - b),
                            step(float3(0.5), a)
                            ), w);
}

static float3 soft_light(float3 a, float3 b, float w) {
  return mix(a, pow(a, pow(float3(2.0), 2.0 * (float3(0.5) - b))), w);
}

fragmentFn(texture2d<float> tex) {
  float2 ps = float2(1.0) / uni.iResolution.xy;
  float2 uv = textureCoord;
  float4 fragColor = tex.sample(iChannel0, uv);
#if SRGB
  fragColor = pow(color, float4(2.2));
#endif
  
  float t = uni.iTime * float(SPEED);
  float seed = dot(uv, float2(12.9898, 78.233));
  float noise = fract(t+rand(seed));
  noise = gaussian(noise, float(MEAN), float(VARIANCE) * float(VARIANCE));
  
#if SHOW_NOISE
  fragColor = float4(noise);
#else
  // Ignore these mouse stuff if you're porting this
  // and just use an arbitrary intensity value.
  float w = float(INTENSITY);
  if (uni.mouseButtons) {
    w = uni.iMouse.y ;
    w *= step(thisVertex.where.xy.x, uni.iMouse.x * uni.iResolution.x);
  }
  
  float3 grain = float3(noise) * (1.0 - fragColor.rgb);
  
#if BLEND_MODE == 0
  fragColor.rgb += grain * w;
#elif BLEND_MODE == 1
  fragColor.rgb = screen(fragColor.rgb, grain, w);
#elif BLEND_MODE == 2
  fragColor.rgb = overlay(fragColor.rgb, grain, w);
#elif BLEND_MODE == 3
  fragColor.rgb = soft_light(fragColor.rgb, grain, w);
#elif BLEND_MODE == 4
  fragColor.rgb = max(fragColor.rgb, grain * w);
#endif
  
#if SRGB
  fragColor = gammaEncode(fragColor);
#endif
#endif
  return fragColor;
}
