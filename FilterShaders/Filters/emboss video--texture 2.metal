
#define shaderName emboss_video__texture_2

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float4 fragColor = tex.sample(iChannel0, textureCoord);
  // extract wavelengths
  fragColor += .5+15.*dfdy( dot(fragColor.xyz, sin(scn_frame.time + float3(0,2.1,-2.1))) ) - fragColor;
  return fragColor;
}
