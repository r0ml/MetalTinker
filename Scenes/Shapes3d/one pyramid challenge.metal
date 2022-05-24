/** 
 Author: FabriceNeyret2
 paradoxically, seems that one needs more chars to draw a pyramid than a cube. or not ? :-)
 from cube version : https://www.shadertoy.com/view/Xs33RH
 
 */

// adapted from the cube version : https://www.shadertoy.com/view/Xs33RH
#define shaderName one_pyramid_challenge

#include "Common.h" 

struct InputBuffer {};
initialize() {}


// draw segment [a,b]
// #define L  ; o+= 3e-3 / length( clamp( dot(u-a,v=b-a)/dot(v,v), 0.,1.) *v - u+a );

// #define P  ; b=c= float2(r.x,-1)/(4.+r.y) L b=float2(0,.4) L  a=c; r = r * (float2x2(0)-float2x2(.5,.87,-.87,.5));

static float2 P(float2 r, thread float2 &a, float2 u, thread float4& o) {
  float2 c= float2(r.x,-1)/(4.+r.y);
  float2 b = c;
  float2 v = b-a;
  o+= 3e-3 / length( saturate( dot(u-a,v)/dot(v,v)) *v - u+a );
  b=float2(0,.4);
  v = b-a;
  o+= 3e-3 / length( saturate( dot(u-a,v)/dot(v,v)) *v - u+a );
  a=c;
  return r * (float2x2(0)-float2x2(.5,.87,-.87,.5));
}

fragmentFn() {
  float2 v = thisVertex.where.xy;
  float2 a = float2(1,-1);
  float2 c=uni.iResolution.xy;
  float2 u = (v+v-c)/c.y;
  float2 r = sin(uni.iDate.w-.8*a);
  r += a*r.yx;
  float4 o = 0;
  r = P(r, a, u, o);
  o= 0;        // just to initialize a
  r = P(r, a, u, o);
  r = P(r, a, u, o);
  r = P(r, a, u, o);   // 3*3 segments
  return o;
}
