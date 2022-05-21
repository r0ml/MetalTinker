
#define shaderName Gloopy

#include "Common.h"

// (((((x - xc1)**2) + ((y - yc1)**2) - (r1**2)) * (((x - xc2)**2) + ((y - yc2)**2) - (r2**2)))) < (s / 1000)

constant const float3 position = float3(-0.2, 0.2, 1.3);
constant const float3 diffuseColour = float3(0.25, 0.25, 0.5);
constant const float diffusePower = 2.0;
constant const float3 specularColour = float3(0.5, 0.1, 0.1);
constant const float specularPower = 5.0;
constant const float specularHardness = 5.0;
constant const float3 ambientColour = float3(0.4, 0.5, 0.4);

static float3 BlinnPhongLighting(float3 pos, float3 viewDir, float3 normal) {
  float3 lightDir = position - pos;
  float distance = length (lightDir);
  lightDir = lightDir / distance;
  distance = distance * distance;
  
  float NdotL = dot (normal, lightDir);
  float intensity = clamp (NdotL, 0.0, 1.0);
  float3 diffuse = intensity * diffuseColour * diffusePower / distance;
  float3 H = normalize (lightDir + viewDir);
  float NdotH = dot (normal, H);
  intensity = pow (clamp (NdotH, 0.0, 1.0), specularHardness);
  float3 specular = intensity * specularColour * specularPower;
  
  return (diffuse + specular + ambientColour);
}

fragmentFunc()
{
  float2 vTextureCoord = textureCoord;
  float time = (310.0 + scn_frame.time) * 1000.0;
//  float width = uni.iResolution.x;
//  float height = uni.iResolution.y;
  
  const float stickiness = 0.0050;
  const float r1 = 0.25;
  const float r2 = 0.25;
  const float r3 = 0.25;
  float2 ratio = nodeAspect;
  float2 pos1 = float2((1.0 + sin(time / 9000.0)) / 2.0, (1.0 + sin(time / 7100.0)) / 2.0) * ratio;
  float2 pos2 = float2((1.0 + sin(time / 8900.0)) / 2.0, (1.0 + sin(time / 10400.0)) / 2.0) * ratio;
  float2 pos3 = float2((1.0 + sin(time / 9650.0)) / 2.0, (1.0 + sin(time / 91500.0)) / 2.0) * ratio;
  float2 pos = vTextureCoord * ratio;
  
  float d1 = pow((pos.x - pos1.x), 2.0) + pow((pos.y - pos1.y), 2.0) - pow(r1, 2.0);
  float d2 = pow((pos.x - pos2.x), 2.0) + pow((pos.y - pos2.y), 2.0) - pow(r2, 2.0);
  float d3 = pow((pos.x - pos3.x), 2.0) + pow((pos.y - pos3.y), 2.0) - pow(r3, 2.0);
  
  float dist = (stickiness - d1 * d2 * d3);
  float3 position = float3(pos.x, pos.y, dist);
  
  float d12 = distance(pos1, pos2);
  float d13 = distance(pos1, pos3);
  float d23 = distance(pos2, pos3);
  float weght12 = 1.0 / (1.0 + exp(((distance(pos1, pos) / d12) - 0.5) * 8.0));
  float weght13 = 1.0 / (1.0 + exp(((distance(pos1, pos) / d13) - 0.5) * 8.0));
  float weght23 = 1.0 / (1.0 + exp(((distance(pos2, pos) / d23) - 0.5) * 8.0));
  
  float2 centre12 = (weght12 * pos1) + ((1.0 - weght12) * pos2);
  float2 centre13 = (weght13 * pos1) + ((1.0 - weght13) * pos3);
  float2 centre = (weght23 * centre12) + ((1.0 - weght23) * centre13);
  
  float up = pow(dist, 0.45);
  float3 normal = normalize(float3(pos.x - centre.x, pos.y - centre.y, up));
  
  float4 colour = float4(0.8 * (1.0 - vTextureCoord.y), 0.8 * vTextureCoord.y, 0.8, 1.0);
  if (dist > 0.0) {
    colour.xyz = BlinnPhongLighting (position, float3(0.0, 0.0, 1.0), normal);
  }
  
  return colour;
}
