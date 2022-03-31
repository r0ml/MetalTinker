
#define shaderName linear_map_circle_to_ellipse

#include "Common.h" 

struct InputBuffer {};
initialize() {}

static float2 ortho(float2 v)
{
  return float2(v.y, -v.x);
}

static float3 stroke(float dist, float3 color, const float3 fc, float thickness, float aa)
{
  float alpha = smoothstep(0.5 * (thickness + aa), 0.5 * (thickness - aa), abs(dist));
  return mix(fc, color, alpha);
}

static float3 fill(float dist, float3 color, const float3 fc, float aa)
{
  float alpha = smoothstep(0.5*aa, -0.5*aa, dist);
  return mix(fc, color, alpha);
}

static float3 renderGrid(float2 pos) // , thread float3& fragColor)
{
  float3 background = float3(1.0);
  float3 axes = float3(0.4);
  float3 lines = float3(0.7);
  float3 sublines = float3(0.95);
  float subdiv = 8.0;
  
  float thickness = 0.003;
  float aa = length(fwidth(pos));
  
  float3 fcl = background;
  
  float2 toSubGrid = pos - round(pos*subdiv)/subdiv;
  fcl = stroke(min(abs(toSubGrid.x), abs(toSubGrid.y)), sublines, fcl, thickness, aa);
  
  float2 toGrid = pos - round(pos);
  fcl = stroke(min(abs(toGrid.x), abs(toGrid.y)), lines, fcl, thickness, aa);
  
  fcl = stroke(min(abs(pos.x), abs(pos.y)), axes, fcl, thickness, aa);
  return fcl;
}

static float sdistLine(float2 a, float2 b, float2 pos)
{
  return dot(pos - a, normalize(ortho(b - a)));
}

static float sdistTri(float2 a, float2 b, float2 c, float2 pos)
{
  return max( sdistLine(a, b, pos),
             max(sdistLine(b, c, pos),
                 sdistLine(c, a, pos)));
}

static float sdistQuadConvex(float2 a, float2 b, float2 c, float2 d, float2 pos)
{
  return max(  sdistLine(a, b, pos),
             max( sdistLine(b, c, pos),
                 max(sdistLine(c, d, pos),
                     sdistLine(d, a, pos))));
}

static float3 renderCircle(float2 center, float radius, float2 pos, float3 fc)
{
  float dist = length(pos - center) - radius;
  return stroke(dist, float3(0, 0, 1), fc, 0.005, length(fwidth(pos)));
}

static float3 renderAxes(float2 origin, float2 pos, const float3 fc)
{
  float len = 0.375 - 6.0 * 0.0075;
  float thickness = 0.0075;
  float aa = length(fwidth(pos));
  
  float xshaft = sdistQuadConvex(origin + float2(0.5*thickness),
                                 origin - float2(0.5*thickness),
                                 origin + float2(len, -0.5*thickness),
                                 origin + float2(len, 0.5*thickness), pos);
  float xhead = sdistTri(origin + float2(len, -2.0*thickness),
                         origin + float2(len + 6.0*thickness, 0),
                         origin + float2(len, 2.0*thickness), pos);
  
  float3 fcl = fill(min(xshaft, xhead), float3(1, 0, 0), fc, aa);
  
  float yshaft = sdistQuadConvex(origin - float2(0.5*thickness),
                                 origin + float2(0.5*thickness),
                                 origin + float2(0.5*thickness, len),
                                 origin + float2(-0.5*thickness, len), pos);
  float yhead = sdistTri(origin + float2(2.0*thickness, len),
                         origin + float2(0, len + 6.0*thickness),
                         origin + float2(-2.0*thickness, len), pos);
  
  return fill(min(yshaft, yhead), float3(0, 0.75, 0), fcl, aa);
  
}

fragmentFn() {
  float2 pos = worldCoordAspectAdjusted / 2;
  
  // animate the grid a bit with rotation, shear, and nonuniform scale
  pos *= float2(sin(uni.iTime*0.72) * 0.5 + 1.0, 1.0);
  pos = pos * rot2d(cos(uni.iTime) * 0.1);
  pos.x += pos.y * sin(uni.iTime*0.89) * 0.5;
  
  float4 fragColor = 0;
  fragColor.a = 1.0;
  fragColor.rgb = renderGrid(pos);
  fragColor.rgb = renderCircle(float2(0), 0.375, pos, fragColor.rgb);
  renderAxes(float2(0), pos, fragColor.rgb);
  return fragColor;
}
