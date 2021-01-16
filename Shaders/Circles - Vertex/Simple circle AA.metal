
#define shaderName simple_circle_aa

#include "Common.h" 

struct InputBuffer {};
initialize() {}

//Slowly pulsate from no anti-aliasing to extreme anti-aliasing
fragmentFn() {
  float aa = (50.0*-cos(uni.iTime)+50.0)/uni.iResolution.y;			//AA diameter
  float2 uv = worldCoordAspectAdjusted / 2;
  float gr = dot(uv,uv); 											//Get Radius point
  
  float cr = (uni.iResolution.y/2.0)/uni.iResolution.x;					//Circle Radius Size (height of screen)
  float2 weight = float2(cr*cr+cr*aa,cr*cr-cr*aa);					//Weight points 0..1
  
  
  return float4(												//Mix
                float3(1.0-saturate((gr-weight.y)/(weight.x-weight.y))),
                1.0
                );
}
