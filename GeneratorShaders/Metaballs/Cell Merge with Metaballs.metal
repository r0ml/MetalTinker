
#define shaderName cell_merge_with_metabals

#include "Common.h" 

static float mBall(float2 uv, float2 pos, float radius)
{
  return radius/dot(uv-pos,uv-pos);
}

fragmentFunc(constant float2& mouse) {
  // float3 color_bg = float3(0.0,0.0,0.0);
  float3 color_inner = float3(1.0,1.0,0.0);
  float3 color_outer = float3(0.5,0.8,0.3);
  
  float2 uv = worldCoordAdjusted;
  float2 mo = (2 * mouse - 1) * nodeAspect;
  
  float mb = 0.;
  
  mb += mBall(uv, float2(0.), 0.02);// metaball 1
  mb += mBall(uv, float2(0.57, 0.), 0.02);// metaball 2
  mb += mBall(uv, float2(sin(scn_frame.time)*.5, 0.5), 0.02);// metaball 3
  mb += mBall(uv, mo, 0.02);// metaball 4
  
  //  float3 col = color_bg;
  float3 mbext = color_outer * (1.-smoothstep(mb, mb+0.01, 0.5)); // 0.5 fro control the blob thickness
  float3 mbin = color_inner * (1.-smoothstep(mb, mb+0.01, 0.8)); // 0.8 for control the blob kernel size
  
  return float4( float3(mbin+mbext), 1);
}
