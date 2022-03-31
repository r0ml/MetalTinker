
#define shaderName simple_effects

#include "Common.h" 

struct InputBuffer {
  struct {
    int channels;
    int contrast;
    int grayscale;
    int invert;
    int noise;
    int sepia;
    int vignette;
  } effect;
};

initialize() {
  in.effect.channels = 1;
}




static float3 invert( float3 color ) {
  return float3(1).rgb - color.rgb;
}

static   float3 contrast( float3 color, float adjust ) {
  adjust = adjust + 1.0;
  return ( color.rgb - float3(0.5) ) * adjust + float3(0.5);
}

static  float randx( float2 co ){
  return rand(co) * 0.5 - 0.25;
}

static  float3 noise( const float3 color, float2 uv, float level ) {
  return max(min(color + float3(randx(uv) * level), float3(1)), float3(0));
}

static  float3 sepia( const float3 color, float adjust ) {
  float cr = min(1.0, (color.r * (1.0 - (0.607 * adjust))) + (color.g * (0.769 * adjust)) + (color.b * (0.189 * adjust)));
  float cg = min(1.0, (color.r * (0.349 * adjust)) + (color.g * (1.0 - (0.314 * adjust))) + (color.b * (0.168 * adjust)));
  float cb = min(1.0, (color.r * (0.272 * adjust)) + (color.g * (0.534 * adjust)) + (color.b * (1.0 - (0.869 * adjust))));
  return float3(cr, cg, cb);
}

static  float3 vignette( float3 color, float2 uv, float adjust ) {
  return color.rgb - max((distance(uv, float2(0.5, 0.5)) - 0.25) * 1.25 * adjust, 0.0);
}

static   float3 channels( const float3 color, float3 channels , float adjust ) {
  if ( all(channels == float3(0)) ) return color;
  float3 clr = color;
  if (channels.r != 0.0) {
    if (channels.r > 0.0) {
      clr.r += (1.0 - clr.r) * channels.r; }
    else {
      clr.r += clr.r * channels.r; }
  }
  if (channels.g != 0.0) {
    if (channels.g > 0.0) {
      clr.g += (1.0 - clr.g) * channels.g; }
    else {
      clr.g += clr.g * channels.g; }
  }
  if (channels.b != 0.0) {
    if (channels.b > 0.0)  {
      clr.b += (1.0 - clr.b) * channels.b; }
    else {
      clr.b += clr.b * channels.b; }
  }
  return clr;
}

fragmentFn(texture2d<float> tex) {
  constexpr sampler iChannel0(coord::normalized, address::repeat, filter::linear);
  float2 uv = textureCoord;
  float3 col = tex.sample(iChannel0, uv).rgb;

  float4 fragColor = 0;
  if (in.effect.grayscale) {
    fragColor = float4(float3(grayscale(col)), 1);
  } else if (in.effect.contrast) {
    fragColor = float4(contrast(col, 1.0), 1);
  } else if (in.effect.invert) {
    fragColor = float4(invert(col), 1);
  } else if (in.effect.noise) {
    fragColor = float4(noise(col, uv, 0.5), 1.0);
  } else if (in.effect.sepia) {
    fragColor = float4(sepia(col, 0.75), 1);
  } else if (in.effect.vignette) {
    fragColor = float4(vignette(col, uv, 1.0), 1);
  } else if (in.effect.channels) {
    fragColor = float4(channels(col, float3(0.2, -0.4, -0.05) , 0.0), 1);
  } else {
    fragColor = float4(0.3, 0.4, 0.5, 0.6);
  }
  return fragColor;
}

