
#define shaderName game_of_life_3

#include "Common.h"

fragmentFn( texture2d<float> lastFrame ) {
// =================

//  float2 h=1./uni.iResolution;
//  float2 v=h;
//  h.y=v.x=0.;

  float3 uv[9];
  neighborhood(lastFrame, uint2(thisVertex.where.xy), uv);

  float nn =  uv[0].x + uv[1].x + uv[2].x + uv[3].x + uv[5].x + uv[6].x + uv[7].x + uv[8].x;     // count life in neighborhood

  int ng  = nn == 3 || (uv[4].x && nn == 2);
  
  if (uni.iFrame < 9 || uni.keyPress.x == ' ') {
    int nng = 0.1 > length(2 * thisVertex.where.xy/uni.iResolution - 1)  ;
    ng = max(ng, nng);
  }

  return float4(ng, ng, ng, 1);
}

