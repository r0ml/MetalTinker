
#define shaderName two_lines_hue_rotation

#include "Common.h" 

static float3 hueRotation(float3 c, float hueRotationAngle){ // <= this is the two lines hue rotation routine
    // By Benjamin 'BeRo' Rosseaux, CC0 licensed 
    float3 hueRotationValues = float3(0.57735, sin(float2(radians(hueRotationAngle)) + float2(0.0, 1.57079632679)));
    return mix(hueRotationValues.xxx * dot(hueRotationValues.xxx, c), c, hueRotationValues.z) + (cross(hueRotationValues.xxx, c) * hueRotationValues.y);
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float3 c = tex.sample(iChannel0, uv).xyz;
   
  float hueRotationAngle = uni.iTime * 180.0;
      
  c = (abs(textureCoord.x - 0.5) < 0.001) ?
        float3(1.0) :
        ((textureCoord.x < 0.5) ?
           hsv2rgb(rgb2hsv(c.xyz) + float3(hueRotationAngle / 360.0, 0.0, 0.0)) : 
           hueRotation(c, hueRotationAngle));
    
  return float4(c, 1.0);
}
