
#define shaderName black_and_white_transformation

#include "Common.h" 
struct InputBuffer {
  bool upside_down = false;
  bool srgb = false;
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  if (in.upside_down) { uv.y = 1.0 - uv.y; }
  float4 fragColor = tex.sample(iChannel0, uv);
  if (in.srgb) {
    fragColor *= fragColor;
    float luminosity = grayscale(fragColor.rgb);
    fragColor.rgb = sqrt(luminosity);
  } else {
    fragColor.rgb = dot(fragColor.rgb, 1) / 3;
  }
  return fragColor;
}


