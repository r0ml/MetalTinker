
#define shaderName fisheye_distortion

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 texturespace_uv = textureCoord;
  
  float aperture = 210.0;
  float apertureHalf = 0.5 * aperture * (PI / 180.0);
  float maxFactor = sin(apertureHalf);
  
  float2 uv;
  float2 xy = worldCoordAdjusted;
  float d = length(xy);
  if (d < (2.0-maxFactor))
  {
    d = length(xy * maxFactor);
    float z = 2.0 * sqrt(1.0 - d * d);
    float r = atan2(d, z) / PI;
    float phi = atan2(xy.y, xy.x);
    
    uv.x = r * cos(phi) + 0.5;
    uv.y = 1 - (r * sin(phi) + 0.5);
    
    // WARP IT A LITTLE BIT
    uv.x += 0.02 * sin(4.0 * scn_frame.time + 15.0 * uv.y);
  }
  else
  {
    uv = texturespace_uv.xy;
  }
  return tex.sample(iChannel0, uv);
}
