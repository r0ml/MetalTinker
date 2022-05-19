
#define shaderName Procedural_film_grain

#include "Common.h"

struct InputBuffer {
  float3 SPEED;
//  float3 INTENSITY;
  float3 MEAN;
  float3 VARIANCE;
  bool NOISE;

  struct {
    int addition;
    int screen;
    int overlay;
    int soft_light;
    int lighten_only;
  } BLEND_MODE;
};

initialize() {
//  in.SRGB = false;
//  in.SHOW_NOISE = false;
  in.SPEED = {1, 2, 5};
//  in.INTENSITY = {0.02, 0.075, 0.5};
  in.MEAN = {-0.5, 0, 0.5}; // What gray level noise should tend to.
  in.VARIANCE = { 0.1, 0.5, 0.9 }; // Controls the contrast/variance of noise.
}

// 0: Addition, 1: Screen, 2: Overlay, 3: Soft Light, 4: Lighten-Only

static float3 channel_mix(float3 a, float3 b, float3 w) {
  return float3(mix(a.r, b.r, w.r), mix(a.g, b.g, w.g), mix(a.b, b.b, w.b));
}

static float gaussian(float z, float u, float o) {
  return (1.0 / (o * sqrt(TAU))) * exp(-(((z - u) * (z - u)) / (2.0 * (o * o))));
}

//static float3 madd(float3 a, float3 b, float w) {
//  return a + a * b * w;
//}

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

fragmentFunc(texture2d<float> tex, constant InputBuffer& in) {
//  float2 ps = float2(1.0) / uni.iResolution.xy;
  float2 uv = textureCoord;
  float4 fragColor = tex.sample(iChannel0, uv);

  float t = scn_frame.time * float(in.SPEED.y);
  float seed = dot(uv, float2(12.9898, 78.233));
  float noise = fract(t+rand(seed));
  noise = gaussian(noise, float(in.MEAN.y), float(in.VARIANCE.y) * float(in.VARIANCE.y));

  noise = noise * in.NOISE;
  
//  if (in.SHOW_NOISE) {
//    fragColor = float4(noise);
//  } else {
  // Ignore these mouse stuff if you're porting this
  // and just use an arbitrary intensity value.

    float w = 1; // float(in.INTENSITY.y);

//    w = uni.iMouse.y ;
//    w *= step(thisVertex.where.xy.x, uni.iMouse.x * uni.iResolution.x);

    float3 grain = float3(noise) * (1.0 - fragColor.rgb);

    if (in.BLEND_MODE.addition) {
      fragColor.rgb += grain * w;
    } else if (in.BLEND_MODE.screen) {
      fragColor.rgb = screen(fragColor.rgb, grain, w);
    } else if (in.BLEND_MODE.overlay) {
      fragColor.rgb = overlay(fragColor.rgb, grain, w);
    } else if (in.BLEND_MODE.soft_light) {
      fragColor.rgb = soft_light(fragColor.rgb, grain, w);
    } else if (in.BLEND_MODE.lighten_only) {
      fragColor.rgb = max(fragColor.rgb, grain * w);
    }
//  }

  return fragColor;
}
