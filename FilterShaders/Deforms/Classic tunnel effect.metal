
#define shaderName classic_tunnel_effect

#include "Common.h"

static float2 tunnel(const float2 pix, float2 reso, float time, thread float& z) {
  float aspect = reso.x / reso.y;
  float2 center = float2(cos(time * 0.15), 0.0);
  float2 pt = (pix * 2.0 - 1.0) * float2(aspect, 1.0);
  
  float2 dir = pt - center;
  
  float angle;
  angle = atan2(dir.y, dir.x) / PI;
  float dist = sqrt(dot(dir, dir));
  z = 2.0 / dist;
  
  return float2(angle * 2.0 + time * 0.25, z + time * 0.5);
}

fragmentFn(texture2d<float> tex) {
  float3 color = float3(1.0, 1.0, 1.0);
  
  float2 tc = textureCoord;
  
  float z;
  float2 tun = tunnel(tc, uni.iResolution, uni.iTime, z);
  
  color = float3(saturate(2.0 / z)) * tex.sample(iChannel0, tun).xyz;
  
  return float4( color, 1);
}

