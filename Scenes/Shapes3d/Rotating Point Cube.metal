/** 
 Author: Zeppelin7
 A cube made up of points with a camera rotating around it.
 */

#define shaderName rotating_point_cube

#include "Common.h" 

struct InputBuffer {};
initialize() {}



float distLine(float3 ro, float3 rd, float3 p) {
  return length(cross(p-ro, rd)) / length(rd);
}

float drawPoint(float3 ro, float3 rd, float3 p) {
  p -= .5; // move cube to center of screen
  float d = distLine(ro, rd, p);
  d = smoothstep(.06, .05, d);
  return d;
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  
  float3 ro = float3(3.*sin(uni.iTime), 2., -3.*cos(uni.iTime)); // ray origin
  
  float3 lookAt = float3(0.);
  
  float zoom = 1.3;
  float3 f = normalize(lookAt - ro);
  float3 r = cross(float3(0.,1.,0.), f);
  float3 u = cross(f, r);
  
  float3 c = ro + f*zoom;
  float3 i = c + uv.x*r + uv.y*u;
  float3 rd = i-ro; // ray dir.
  
  // float t = uni.iTime;
  
  float d = 0.;
  
  d += drawPoint(ro, rd, float3(0., 0., 0.));
  d += drawPoint(ro, rd, float3(0., 0., 1.));
  d += drawPoint(ro, rd, float3(0., 1., 0.));
  d += drawPoint(ro, rd, float3(0., 1., 1.));
  d += drawPoint(ro, rd, float3(1., 0., 0.));
  d += drawPoint(ro, rd, float3(1., 0., 1.));
  d += drawPoint(ro, rd, float3(1., 1., 0.));
  d += drawPoint(ro, rd, float3(1., 1., 1.));
  
  return float4(d);
}
