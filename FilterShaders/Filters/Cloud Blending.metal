
#define shaderName Cloud_Blending

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

static float fbm(const float2 p) {
  return  .5000 * noisePerlin(p) +.2500 * noisePerlin(p * 2.) +.1250 * noisePerlin(p * 4.) +.0625 * noisePerlin(p * 8.);
}


fragmentFn(texture2d<float> tex) {
  float2 b = textureCoord;
  float cloudVal = (fbm(b+uni.iTime));
  
  float3 backPx = tex.sample( iChannel0, b ).rgb;
  float3 frontPx = float3(0.3, 0.3, 0.3);
  return float4( mix(backPx, frontPx, cloudVal), 1);
}