
#define shaderName c1_Brannan_Filter

#include "Common.h"

static float3 overlay(const float3 s, const float3 d ) {
    float3 l = 2 * s * d;
    float3 r = 1 - 2 * (1-s) * (1-d);
    return mix(r, l, float3(d<0.5));
  }

static float3x3 saturationMatrix( float saturation ) {
    float3 luminance = float3( 0.3086, 0.6094, 0.0820 );
    float oneMinusSat = 1.0 - saturation;
    float3 red = float3( luminance.x * oneMinusSat );
    red.r += saturation;

    float3 green = float3( luminance.y * oneMinusSat );
    green.g += saturation;

    float3 blue = float3( luminance.z * oneMinusSat );
    blue.b += saturation;

    return float3x3(red, green, blue);
  }

static float3 levels(const float3 col, const float3 inleft, const float3 inright, const float3 outleft, const float3 outright) {
    float3 res = clamp(col, inleft, inright);
    res = (res - inleft) / (inright - inleft);
    return outleft + res * (outright - outleft);
  }

static float3 contrastAdjust( const float3 color, const float c) {
    return 0.5 + c * (color - 0.5);
  }

fragmentFn(texture2d<float> tex) {
  const float3 tint = float3(255., 248., 242.) / 255.;

  float2 uv = textureCoord;
  float3 ocol = tex.sample(iChannel0, uv).rgb;

  float3 grey = grayscale(ocol);
  float3 col = saturationMatrix(0.7) * ocol;
  grey = overlay(grey, col);
  col = mix(grey, col, 0.63);
  col = levels(col, 0, float3(228., 255., 239.) / 255., float3(23., 3., 12.) / 255., 1);
  col = saturate(contrastAdjust(col - 0.1, 1.05));
  col = levels(col, 0, float3(255., 224., 255.) / 255., float3(9., 20., 18.) / 255., 1);
  col = pow(col, float3(0.91, 0.91, 0.91*0.94));
  col = saturate(contrastAdjust(col - 0.04, 1.14));
  col = tint * col;
  col = sqrt(col);
  return float4( mix(col, ocol, uv.x > uni.iMouse.x ), 1);
}
