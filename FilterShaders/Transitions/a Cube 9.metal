
#define shaderName a_Cube_9

#include "Common.h" 

constant const float persp = .7;
constant const float unzoom = .3;
constant const float reflection = .4;
constant const float floating = 3.;

static float2 project (float2 p)
{
  return p * float2(1, -1.2) + float2(0, -floating/100.);
}

static bool inBounds (float2 p)
{
  return all( float2(0) < p ) && all( p < float2(1));
}

static float4 bgColor (float2 p, float2 pfr, float2 pto, texture2d<float> vid0, texture2d<float> vid1)
{
  float4 c = float4(0, 0, 0, 1);
  pfr = project(pfr);
  if (inBounds(pfr))
  {
    c += mix(float4(0), vid0.sample(iChannel0, pfr), reflection * mix(1., 0., pfr.y));
  }
  pto = project(pto);
  if (inBounds(pto))
  {
    c += mix(float4(0), vid1.sample(iChannel0, pto), reflection * mix(1., 0., pto.y));
  }
  return c;
}

// p : the position
// persp : the perspective in [ 0, 1 ]
// center : the xcenter in [0, 1] \ 0.5 excluded
static float2 xskew (float2 p, float persp, float center)
{
  float x = mix(p.x, 1.-p.x, center);
  return (
          (
           float2( x, (p.y - .5*(1.-persp) * x) / (1.+(persp-1.)*x) )
           - float2(.5-distance(center, .5), 0)
           )
          * float2(.5 / distance(center, .5) * (center<0.5 ? 1. : -1.), 1.)
          + float2(center<0.5 ? 0. : 1., .0)
          );
}

fragmentFunc(texture2d<float> tex0, texture2d<float> tex1, constant float2& mouse) {
//  float progress = sin(uni.iTime*0.6+10.)*.5+.5;
  float progress = mouse.x;

  float2 op = textureCoord;
  float uz = unzoom * 2.0*(0.5-distance(0.5, progress));
  float2 p = -uz*0.5+(1.0+uz) * op;
  float2 fromP = xskew(
                       (p - float2(progress, 0.0)) / float2(1.0-progress, 1.0),
                       1.0-mix(progress, 0.0, persp),
                       0.0
                       );
  float2 toP = xskew(
                     p / float2(progress, 1.0),
                     mix(pow(progress, 2.0), 1.0, persp),
                     1.0
                     );
  if (inBounds(fromP))
  {
    return tex0.sample(iChannel0, fromP);
  }
  else if (inBounds(toP))
  {
    return tex1.sample(iChannel0, toP);
  }
  else
  {
    return bgColor(op, fromP, toP, tex0, tex1);
  }
}
