
#define shaderName Circles_intersections

#include "Common.h"

struct InputBuffer {  };
initialize() {}





static float Circle(float2 pix, float3 C){
  float r = length(C.xy - pix);
  float d = abs(r - C.z);
  return smoothstep(0.03, 0.015, d) + 0.5*smoothstep(0.1, 0.0, r - C.z);
}

static float Point(float2 pix, float2 X){
  float r = length(X - pix);
  return smoothstep(0.04, 0.00, r);
}

/* xy : first intersection point
 zw : second intersection point */
static float4 IntersectCircles(float3 c1, float3 c2)
{
  // set c1 to the origin
  c2.xy -= c1.xy;
  float z = dot(c2.xy, c2.xy);
  
  float3 l = float3(c1.z*c1.z, c2.z*c2.z, z);
  float a = l.x - l.y + l.z;
  float b = sqrt(dot(l, 2.0*l.zxy-l));
  
  float2 j1 = a*c2.xy + b*float2(-c2.y, c2.x);
  float2 j2 = a*c2.xy - b*float2(-c2.y, c2.x);
  
  return float4(c1.xy, c1.xy) + float4(j1,j2)/(2.0*z);
}

static float3 Background(float2 p){
  return length(p) * float3(0.4 + 0.1*p.y, 0.2 + 0.2*p.y, 0.15*p.x);
}

static float2 Mouse(float2 mouse, float2 reso) {
  float2 r = 2.0 * mouse - 1.0;
  r.x *= reso.x / reso.y;
  return r;
}

static float3 Scene(float2 pix, float time, float2 mouse, float2 reso){
  float3 col = Background(pix);
  
  float3 circle1 = float3(0.0, -0.3, 0.5);
  float3 circle2 = float3(0.2, 0.2, 0.7);
  circle1.xy = Mouse(mouse, reso);
  circle1.z = 0.7 + abs(0.1*sin(0.3*time));
  
  col += float3(0.1, 0.2, 0.7) * Circle(pix, circle1);
  col += float3(0.7, 0.0, 0.3) * Circle(pix, circle2);
  
  float4 iC = IntersectCircles(circle1, circle2);
  col -= (0.7*col-float3(0.1, 0.9, 0.7)) * (Point(pix, iC.xy) + Point(pix, iC.zw));
  
  return col;
}

fragmentFn() {
  float2 p = worldCoordAspectAdjusted;
  
  float3 col = Scene(p, uni.iTime, uni.iMouse, uni.iResolution);
  
  
  return float4(col, 1.0);
}
