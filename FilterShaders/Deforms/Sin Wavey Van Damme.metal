
#define shaderName sin_wavey_van_damme

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  // Normalised pixel position
  float2 uv = textureCoord; // pixelPos_n
  
  // Amount to offset a row by
  float rowOffsetMagnitude = sin(uni.iTime*10.0) * 0.05;
  
  // Determine the row the pixel belongs too
  float row = floor(uv.y/0.001);
  // Offset Pixel according to its row
  uv.x +=  sin(row/100.0)*rowOffsetMagnitude;
  
  // set pixel color
  return tex.sample(iChannel0, uv);
}
