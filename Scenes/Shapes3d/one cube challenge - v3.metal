/** 
 Author: FabriceNeyret2
 the line-drawing version
 See instructions here: https://www.shadertoy.com/view/ldd3zr
 */

#define shaderName one_cube_challenge_v3

#include "Common.h" 

struct InputBuffer {};
initialize() {}


// reduction by Coyote: 262
// draw segment [a,b]
// #define L  *I ; o+= 3e-3 / length( clamp( dot(u-a,v=b-a)/dot(v,v), 0.,1.) *v - u+a )
// #define P  ; b=c= float2(r.x,1)/(4.+r.y) L;   b=a L;   a=c L;   a=c; r= I*r.yx;

static float2 P(const float2 r, thread float2 &a, float2 u, thread float4& o) {
  float2 I=float2(1,-1);
  float2 c= (float2(r.x,1)/(4.+r.y)) * I;
  float2 b = c;
  float2 v = b-a;
  o += 3e-3 / length( saturate( dot(u-a,v)/dot(v,v)) *v - u+a );
  b = a * I;
  v = b - a;
  o+= 3e-3 / length( saturate( dot(u-a,v)/dot(v,v)) *v - u+a );
  a=c * I;
  v = b - a;
  o+= 3e-3 / length( saturate( dot(u-a,v)/dot(v,v)) *v - u+a );
  a=c;
  return I*r.yx;
}

fragmentFn() {
  float2 I=float2(1,-1);
  float2 a = 0;
  float2 u = worldCoordAspectAdjusted;
  float2 r = sin(uni.iDate.w-.8*I); r += I*r.yx  ;  // .8-.8*I = float2(0,1.6)
  float4 o = 0;
  r = P(r, a, u, o);
  o = 0; // just to initialize a
  r = P(r, a, u, o);
  r = P(r, a, u, o);
  r = P(r, a, u, o);
  r = P(r, a, u, o);  // 4*3 segments
  return o;
}
