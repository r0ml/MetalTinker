
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#ifndef sdf_h
#define sdf_h

float sdSphere( float3 p, float radius, float3 origin = 0 );
float sdBox( float3 p, float3 sides );
float sdTorus( float3 p, float outerRadius, float innerRadius, float3 center = 0 );
float sdPlane( float3 p, float4 n = float4(0, 1, 0, 0) );

// -------------------------------------------------------

float sdCircle(float2 p, float r, float2 origin = 0 );
float sdSegment( float2 p, float2 a, float2 b );

// -------------------------------------------------------

float sdSubtract( float d1, float d2);
float sdUnion( float d1, float d2 );
float sdIntersect(float a, float b);

// ======================================================

float3 opRep( float3 p, float3 c );

#endif /* sdf_h */
