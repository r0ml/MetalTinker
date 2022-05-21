
#define shaderName cell_merge_v1

#include "Common.h" 

#define cellCount 20.0

static float3 powerToColor(float2 power, float mapScale, float3 color_bg, float3 color_outer, float3 color_inner)
{
  float tMax = pow(1.03,mapScale*2.2);
  float tMin = 1.0 / tMax;
  
  float3 color = mix(color_bg, color_outer, smoothstep(tMin,tMax,power.y));
  color = mix(color, color_inner, smoothstep(tMin,tMax,power.x));
  return color;
}


static float2 getCellPower( float2 coord, float2 pos, float2 size )
{
  float2 power;
  
  power = (size*size) / dot(coord-pos,coord-pos);
  power *= power * sqrt(power); // ^5
  
  return power;
}


fragmentFunc() {

  float3 color_bg = float3(0.0);
  float3 color_inner = float3(1.0,0.9,0.16);

  float3 color_outer = float3(0.12,0.59,0.21);
  //float3 color_outer = mix(color_bg, color_inner, 0.3); // also nice effect
  // size in pixels inner/outer with mapscale 1.0
  float2 cellSize = float2(30.0, 44.0);


  float timeScale = 1.0;
  float mapScale = 1.0;

  float T = scn_frame.time * 0.1 * timeScale / mapScale;
  
  float2 hRes = 2 / scn_frame.inverseResolution;
  
  float2 pos;
  float2 power = float2(0.0,0.0);
  
  
  for(float x = 1.0; x != cellCount + 1.0; ++x)
  {
    pos = hRes * float2(sin(T*fract(0.246*x)+x*3.6)*cos(T*fract(0.374*x)-x*fract(0.6827*x))+1.,
                        cos(T*fract(0.4523*x)+x*5.5)*sin(T*fract(.128*x)+x*fract(0.3856*x))+1.);
    
    power += getCellPower(thisVertex.where.xy.xy, pos, cellSize*(.75+fract(0.2834*x)*.25) / mapScale);
  }
  
  return float4( powerToColor(power, mapScale, color_bg, color_outer, color_inner), 1);
}
