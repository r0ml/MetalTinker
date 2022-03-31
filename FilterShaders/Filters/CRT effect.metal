
#define shaderName CRT_effect

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

static float2 crt_coords(float2 uv, float bend) {
  uv -= 0.5;
  uv *= 2.;
  uv.x *= 1. + pow(abs(uv.y)/bend, 2.);
  uv.y *= 1. + pow(abs(uv.x)/bend, 2.);
  
  uv /= 2.5;
  return uv + .5;
}

static float vignette(float2 uv, float size, float smoothness, float edgeRounding) {
  uv -= .5;
  uv *= size;
  float amount = sqrt(pow(abs(uv.x), edgeRounding) + pow(abs(uv.y), edgeRounding));
  amount = 1. - amount;
  return smoothstep(0., smoothness, amount);
}

static float scanline(float2 uv, float lines, float speed, float time)
{
  return sin(uv.y * lines + time * speed);
}

static float random(float2 uv, float time)
{
  return fract(sin(dot(uv, float2(15.5151, 42.2561))) * 12341.14122 * sin(time * 0.03));
}

static float noise(float2 uv, float time)
{
  float2 i = floor(uv);
  float2 f = fract(uv);
  
  float a = random(i, time);
  float b = random(i + float2(1.,0.), time);
  float c = random(i + float2(0., 1.), time);
  float d = random(i + float2(1.), time);
  
  float2 u = smoothstep(0., 1., f);
  
  return mix(a,b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;
  
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  
  float2 crt_uv = crt_coords(uv, 4.);
  
  float s1 = scanline(uv, 200., -10., uni.iTime);
  float s2 = scanline(uv, 20., -3., uni.iTime);
  
  float4 col;
  col.r = tex.sample(iChannel0, crt_uv + float2(0., 0.01)).r;
  col.g = tex.sample(iChannel0, crt_uv).r;
  col.b = tex.sample(iChannel0, crt_uv + float2(0., -0.01)).b;
  col.a = tex.sample(iChannel0, crt_uv).a;
  
  col = mix(col, float4(s1 + s2), 0.05);
  return mix(col, float4(noise(uv * 75., uni.iTime)), 0.05) * vignette(uv, 1.9, .6, 8.);;
}
