
#define shaderName a_Cube_2

#include "Common.h"

struct InputBuffer { };
initialize() {}




#define MAX_STEPS 96
#define MIN_DIST 0.001
#define NORMAL_SMOOTHNESS 0.02

static float Box(float radius, float3 position)
{
  return max(max(abs(position.x), abs(position.y)), abs(position.z)) - radius;
}

static float Scene(float3 position, float time)
{
  float map = -sdSphere(position, 24.0);
  
  float animTime = mod(time, 10.0);
  
  float xScale = smoothstep(1.0, 1.5, animTime) - smoothstep(6.0, 6.5, animTime);
  float zScale = smoothstep(2.0, 2.5, animTime) - smoothstep(7.0, 7.5, animTime);
  float yScale = smoothstep(3.0, 3.5, animTime) - smoothstep(8.0, 8.5, animTime);
  
  for(int i = -1; i <= 1;i++)
  {
    for(int j = -1; j <= 1;j++)
    {
      for(int k = -1; k <= 1;k++)
      {
        float3 offset = float3(i,j,k) * 2.0;
        
        offset.x *= 1.0 + xScale;
        offset.y *= 1.0 + yScale;
        offset.z *= 1.0 + zScale;
        
        map = sdUnion(map, Box(1.0, position + offset));
      }
    }
  }
  
  return map;
}

static float3 Normal(float3 position, float time)
{
  float3 offset = float3(NORMAL_SMOOTHNESS, 0, 0);
  
  float3 normal = float3
  (
   Scene(position - offset.xyz, time) - Scene(position + offset.xyz, time),
   Scene(position - offset.zxy, time) - Scene(position + offset.zxy, time),
   Scene(position - offset.yzx, time) - Scene(position + offset.yzx, time)
   );
  
  return normalize(normal);
}

static float3 RayMarch(float3 origin,float3 direction, float time)
{
  float hitDist = 0.0;
  for(int i = 0;i < MAX_STEPS;i++)
  {
    float sceneDist = Scene(origin + direction * hitDist, time);
    
    hitDist += sceneDist;
    
    if(sceneDist < MIN_DIST)
    {
      break;
    }
  }
  
  return origin + direction * hitDist;
}

static float3 Shade(float3 position, float3 normal, float3 rayOrigin,float3 rayDirection)
{
  float3 color = float3(0, 0, 0);
  
  //Face Colors
  float3 leftColor =  float3(  3, 130,  75) / 255.0;
  float3 frontColor = float3(233, 207,  12) / 255.0;
  float3 topColor =   float3(215,  75,   4) / 255.0;
  
  color = mix(color, leftColor,  abs( dot(normal, float3(1,0,0) ) ) );
  color = mix(color, frontColor, abs( dot(normal, float3(0,0,1) ) ) );
  color = mix(color, topColor,   abs( dot(normal, float3(0,1,0) ) ) );
  
  //Background
  color = mix(color, float3(0.1), step(22.0, length(position)));
  
  return color;
}

fragmentFn()
{
  float2 aspect = uni.iResolution.xy / uni.iResolution.y;
  float2 uv = thisVertex.where.xy.xy / uni.iResolution.y;
  
  float2 mouse = uni.iMouse.xy ;
  
  float2 mouseAngle = float2(0);
  
  mouseAngle.x = PI * mouse.y + PI/2.0;
  mouseAngle.x += PI/3.0;
  
  mouseAngle.y = 2.0 * PI * -mouse.x;
  mouseAngle.y += PI/4.0;
  
  float3 rayOrigin = float3(0 , 0, -20.0);
  float3 rayDirection = normalize(float3(uv - aspect / 2.0, 1.0));
  
  float2x2 rotateX = rot2d(mouseAngle.x);
  float2x2 rotateY = rot2d(mouseAngle.y);
  
  rayOrigin.yz = rayOrigin.yz * rotateX;
  rayOrigin.xz = rayOrigin.xz * rotateY;
  rayDirection.yz = rayDirection.yz * rotateX;
  rayDirection.xz = rayDirection.xz * rotateY;
  
  float3 scenePosition = RayMarch(rayOrigin, rayDirection, uni.iTime);
  
  float3 outColor = Shade(scenePosition,Normal(scenePosition, uni.iTime),rayOrigin,rayDirection);
  
  return float4(outColor, 1.0);
}
