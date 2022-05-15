
#define shaderName black_and_white_fade

#include "Common.h"
struct InputBuffer {
  bool srgb = false;
};

fragmentFunc(device InputBuffer &in, texture2d<float> tex) {
  float4 fragColor = tex.sample(iChannel0, textureCoord );
  
  float cColor = 0.5 + 0.5*sin(scn_frame.time);
  float cValue;

//  float cValue = max(max(fragColor.x,fragColor.y),fragColor.z);
  
/*  fragColor.x = mix(fragColor.x,cValue,cColor);
  fragColor.y = mix(fragColor.y,cValue,cColor);
  fragColor.z = mix(fragColor.z,cValue,cColor);
  fragColor.w = 1;
  return fragColor;
*/


  if (in.srgb) {
    fragColor *= fragColor;
    float luminosity = grayscale(fragColor.rgb);
    cValue = sqrt(luminosity);
  } else {
    cValue = dot(fragColor.rgb, 1) / 3;
  }

  fragColor.rgb = mix(fragColor.rgb, cValue, cColor);
  return fragColor;
}
