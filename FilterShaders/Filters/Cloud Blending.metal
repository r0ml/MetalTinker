
#define shaderName Cloud_Blending

#include "Common.h" 

static float fbm(const float2 p) {
  return  .5000 * noisePerlin(p) +.2500 * noisePerlin(p * 2.) +.1250 * noisePerlin(p * 4.) +.0625 * noisePerlin(p * 8.);
}


fragmentFunc(texture2d<float> tex) {
  float2 b = textureCoord;
  float cloudVal = (fbm(b+scn_frame.time));
  
  float3 backPx = tex.sample( iChannel0, b ).rgb;
  float3 frontPx = float3(0.3, 0.3, 0.3);
  return float4( mix(backPx, frontPx, cloudVal), 1);
}
