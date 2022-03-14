
#define shaderName c1_Earlybird_Filter

#include "Common.h"

struct InputBuffer {
};

initialize() {
}

namespace shaderName {

  float3x3 saturationMatrix( float saturation ) {
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

  void levels(thread float3& col, const float3 inleft, const float3 inright, const float3 outleft, const float3 outright) {
    col = clamp(col, inleft, inright);
    col = (col - inleft) / (inright - inleft);
    col = outleft + col * (outright - outleft);
  }

  void brightnessAdjust( thread float3& color, const float b) {
    color += b;
  }

  void contrastAdjust( thread float3& color, const float c) {
    float t = 0.5 - c * 0.5;
    color = color * c + t;
  }

  float3 colorBurn(const float3 s, const float3 d ) {
    return 1.0 - (1.0 - d) / s;
  }
}

using namespace shaderName;

fragmentFn(texture2d<float> tex) {
  float3 col = tex.sample(iChannel0, textureCoord ).rgb;
  if (uni.mouseButtons) {
    return float4(col, 1.0);
  }
  //  float2 coord = 2 * thisVertex.barrio.xy - 1;
  // FIXME: I should maybe adjust for aspect ratio
  
  float2 ccc = worldCoordAspectAdjusted;
  float jjj = length(ccc * 0.4);
  float3 gradient = pow(1.0 - jjj, 0.6) * 1.2;
  float3 grey = 184./255.;
  float3 tint = float3(252., 243., 213.) / 255.;
  col = saturationMatrix(0.68) * col;
  levels(col, float3(0.), float3(1.0), float3(27.,0.,0.) / 255., float3(255.) / 255.);
  col = pow(col, 1.19);
  brightnessAdjust(col, 0.13);
  contrastAdjust(col, 1.05);
  col = saturationMatrix(0.85) * col;
  levels(col, float3(0.), float3(235./255.), float3(0.,0.,0.) / 255., float3(255.) / 255.);
  
  col = mix(tint * col, col, gradient);
  col = colorBurn(grey, col);
  return float4(col, 1.0);
}
