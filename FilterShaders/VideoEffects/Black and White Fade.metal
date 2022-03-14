
#define shaderName black_and_white_fade

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  // float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  float4 fragColor = tex.sample(iChannel0, textureCoord );
  
  float cColor = 0.5 + 0.5*sin(uni.iTime);
  float cValue = max(max(fragColor.x,fragColor.y),fragColor.z);
  
  fragColor.x = mix(fragColor.x,cValue,cColor);
  fragColor.y = mix(fragColor.y,cValue,cColor);
  fragColor.z = mix(fragColor.z,cValue,cColor);
  fragColor.w = 1;
  return fragColor;
}
