//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

#define shaderName not_used
#include "Common.h"

#include <metal_stdlib>
using namespace metal;

float sdSphere( float3 p, float radius, float3 origin ) {
  return distance(p, origin)-radius;
}

float sdBox( float3 p, float3 sides ) {
  float3 d = abs(p) - sides;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdTorus( float3 p, float outerRadius, float innerRadius, float3 center ) {
  float2 q = float2(length(p.xz - center.xz)-outerRadius, p.y - center.y);
  return length(q)-innerRadius;
}

// n must be normalized
float sdPlane( float3 p, float4 n ) {
  return dot(p, normalize(n.xyz) ) + n.w;
}

// ------------------------------------------


float sdCircle (float2 p, float r, float2 origin) {
  return distance(p, origin) - r;
}

float sdSegment( float2 p, float2 a, float2 b ) {
  float2 pa = p-a, ba = b-a;
  float h = saturate( dot(pa,ba)/dot(ba,ba));
  return length( pa - ba*h );
}

// ------------------------------------------

// subtract the second thing from the second
float sdSubtract( float d1, float d2 ) {
  return max(-d2,d1);
}

// union of two shapes
float sdUnion( float d1, float d2 ) {
    return min(d1,d2);
}

float sdIntersect(float a, float b) {
  return max(a,b);
}

//======================================================

float3 opRep( float3 p, float3 c ) {
    return mod(p,c)-0.5*c;
}
