
#define shaderName Spirograph_Plotter

#include "Common.h"

initialize() {}


#define polar(l,a) (l*float2(cos(a),sin(a)))

constant const float timeScale = 1.0;

static float distLine(float2 p0,float2 p1,float2 uv)
{
  float2 dir = normalize(p1 - p0);
  uv = (uv - p0) * float2x2(dir.x, dir.y,-dir.y, dir.x);
  return distance(uv, clamp(uv, float2(0), float2(distance(p0, p1), 0)));
}

//Spirograph function (change these numbers to get different patterns)
static float2 spirograph(float t)
{
  return polar(0.30, t * 1.0)
  + polar(0.08, t *-4.0)
  + polar(0.06, t *-8.0)
  + polar(0.05, t * 16.0)
  + polar(0.02, t * 24.0);
}

fragmentFn1() {
  FragmentOutput f;
  f.fragColor = renderInput[0].read(uint2(thisVertex.where.xy / uni.iResolution));
  
  
  float frameTime = (1.0 / 60.0) * timeScale;
  
  float2 aspect = uni.iResolution.xy / uni.iResolution.y;
  float2 uv = thisVertex.where.xy / uni.iResolution.y - aspect/2.0;
  
  float lineRad = 1.0 / uni.iResolution.y;
  
  float curTime = uni.iTime * timeScale;
  float lastTime = curTime - frameTime;
  
  float dist = distLine(spirograph(curTime), spirograph(lastTime), uv);
  
  float3 col = float3(0.0);
  
  //Click to reset
  if (uni.mouseButtons) {
    col = float3(0.0);
  } else {
    if(dist < lineRad) {
      col = float3(1.0);
    } else {
      col = f.fragColor.rgb;
    }
  }
  
  f.pass1 = float4(col,1.0);
  return f;
}
