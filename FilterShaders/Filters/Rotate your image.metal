
#define shaderName rotate_your_image

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

static float exponentialInOut(float t) {
  return t == 0.0 || t == 1.0
  ? t
  : t < 0.5
  ? +0.5 * pow(2.0, (20.0 * t) - 10.0)
  : -0.5 * pow(2.0, 10.0 - (t * 20.0)) + 1.0;
}

fragmentFn(texture2d<float> tex) {
  // params
  float2 textureOffset = float2(-0.5);
  float easedProgress = exponentialInOut(mod(uni.iTime * 0.3, 1.));
  float rotation = easedProgress * TAU;
  float aspect = 5.32/3.;
  float zoom = 0.872;
  zoom += 0.6 * sin(rotation / 2.);
  
  // rotate
  float2 uv = textureCoord;
  uv = float2((uv.x - 0.5) * (uni.iResolution.x / uni.iResolution.y), uv.y - 0.5);
  uv *= (2. - zoom) / 2.;
  uv *= rot2d(rotation);
  uv.y *= aspect;
  return tex.sample(iChannel0, uv - textureOffset);
}


