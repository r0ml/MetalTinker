
// FIXME: figure out how to use a mask

#define shaderName lights_and_shadows

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord * 2;

  // Time varying pixel color
  // float3 col = 0.5 + 0.5*cos(uni.iTime+uv.xyx+float3(0,2,4));

  float4 texr = tex.sample(iChannel0, uv);

  // float3 light_pos = float3(2.0 * uni.iMouse.x / uni.iResolution.x - 1.0,
  //                        2.0 * uni.iMouse.y / uni.iResolution.y - 1.0,
  //                        0.002);

  // float dist = distance(uv.xy, light_pos.xy);

  float2 d =  (textureCoord - uni.iMouse.xy) * uni.iResolution;
  float2 s = .15 * uni.iResolution.xy;
  float r = dot(d, d)/dot(s,s);

  /* Phong
   float4 norm = normalize(texr);
   float3 NormalVector = float3(norm.x, norm.y, norm.z);

   float4 white = float4(1.);
   float3 LightVector = normalize(float3(light_pos.x - thisVertex.where.x, light_pos.y - thisVertex.where.y, 60.0) + 0.5);

   float diffuse = max( dot(NormalVector, LightVector), 0.0);

   float distanceFactor = (1. - dist / (light_pos.z * uv.x));
   */

  return float4(texr.rgb * (1.5 - r), 1);
}
