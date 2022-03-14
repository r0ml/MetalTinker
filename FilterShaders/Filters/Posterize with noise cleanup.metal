
#define shaderName Posterize_with_noise_cleanup

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

#define stepH 1.
#define stepV 1.

static float rgbToGray(float4 rgba) {
  const float3 W = float3(0.2125, 0.7154, 0.0721);
  return dot(rgba.xyz, W);
}

fragmentFn(texture2d<float> tex) {
  float posterSteps = 8.;

  // current location & color
  float2 uv = textureCoord;
  
  //   float4 curColor = texture[0].sample(iChannel0, uv);

  // get samples around pixel
  float colors[9];
  float stepX = stepH/uni.iResolution.x;
  float stepY = stepV/uni.iResolution.y;
  colors[0] = rgbToGray(tex.sample(iChannel0, uv + float2(-stepX, stepY)));
  colors[1] = rgbToGray(tex.sample(iChannel0, uv + float2(0, stepY)));
  colors[2] = rgbToGray(tex.sample(iChannel0, uv + float2(stepX, stepY)));
  colors[3] = rgbToGray(tex.sample(iChannel0, uv + float2(-stepX, 0)));
  colors[4] = rgbToGray(tex.sample(iChannel0, uv));
  colors[5] = rgbToGray(tex.sample(iChannel0, uv + float2(stepX, 0)));
  colors[6] = rgbToGray(tex.sample(iChannel0, uv + float2(-stepX, -stepY)));
  colors[7] = rgbToGray(tex.sample(iChannel0, uv + float2(0, -stepY)));
  colors[8] = rgbToGray(tex.sample(iChannel0, uv + float2(stepX, -stepY)));

  // apply color steps to original color
  for(int i=0; i < 9; i++) {
    colors[i] = floor(colors[i] * posterSteps) / posterSteps;
  }

  // count up colors in totals count array
  int colorsCount[9];
  for(int i=0; i < 9; i++) {
    colorsCount[i] = 0;
    for(int j=0; j < 9; j++) {
      if(colors[i] == colors[j]) colorsCount[i] += 1;
    }
  }

  // find most common color in kernel
  int maxColors = 0;
  int maxIndex = 0;
  for(int i=0; i < 9; i++) {
    if(colorsCount[i] > maxColors) {
      maxColors = colorsCount[i];
      maxIndex = i;
    }
  }

  // draw most common color in kernel (or original)
  return mix(float4(float3(colors[maxIndex]), 1.0), float4(float3(colors[4]), 1.0), mod(uni.iTime, 1.) > 0.5);
}
