//
//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml
//

#ifndef glsl_h
#define glsl_h

#include <metal_stdlib>
using namespace metal;

template <typename T>
static T mod(T x, float y) {
  return x - y * floor(x/y);
}

template <typename T>
static T mod(T x, typename enable_if<true,T>::type y) {
  return x - y * floor(x/y);
}

float normalize(float);

int packSnorm2x16(float2);
uint packUnorm2x16(float2);
float2 unpackSnorm2x16(int);
float2 unpackUnorm2x16(int);

template <typename T>
static T radians(T x) {
  return M_PI_F * x / 180.0;
}

template <typename T>
static T degrees(T x) {
  return 180.0 * x / M_PI_F;
}

/*
template <typename T>
static T atan(T x, T y) {
  return atan2(x, y);
}
 */

template <typename T>
static T inversesqrt(T x) {
  return 1 / sqrt(x);
}

float4 textureLod(texture2d<float>, sampler, float2, float );
float4 textureLod(texturecube<float>, sampler, float3, float );

float4 textureGrad(texture2d<float> tx, sampler s, float2 p, float2 x, float2 y );
float4 texelFetch(texture2d<float> tx, uint2, uint = 0);
float4 texelFetch(texture1d<float> tx, uint);
float4 texelFetch(texture2d<float> tx, int2, int = 0);
float distance(float, float);

float4x4 mat3to4(float3x3);

float4x4 inverse(float4x4);
float3x3 inverse(float3x3);
float2x2 inverse(float2x2);

float dot(float, float);

#endif /* glsl_h */
