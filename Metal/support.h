
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#ifndef support_h
#define support_h

using namespace metal;

#include <metal_stdlib>
#include "constants.h"

float fix_atan2(float, float);

static constexpr sampler iChannel0(coord::normalized, address::repeat, filter::linear);
// static constexpr sampler iChannel2(coord::normalized, address::clamp_to_edge, filter::nearest);

template <typename T>
static T fix_sin(T x) {
  return sin(fmod(x, M_PI_F * 2));
}

template <typename T>
static T fix_cos(T x) {
  return cos(fmod(x, M_PI_F * 2));
}

float2x2 rot2d(float);
float2x2 rot2dpi(float);

float3x3 rotate( float3 axis, float angle);
float3x3 rotX( float angle);
float3x3 rotY( float angle);
float3x3 rotZ( float angle);

float2x2 makeMat(float4);

// convert rgb to grayscale
float grayscale(float3); // rgb to yiq
float luminance(float3); // srgb
float3 rgb2hsv(float3);
float3 hsv2rgb(float3);

float3 gammaEncode(float3 c);
float4 gammaEncode(float4 c);
float3 gammaDecode(float3 c);
float4 gammaDecode(float4 c);

// ==========================================================
// random numbers
// =========================== ===============================
float4 rand4(float2);
float3 rand3(float2, float = 0);
float2 rand2(float2);

// float rand(float2);
float rand( float n);
float rand( float2 n);
float rand( float3 n);


float4 prand4(float2, float2);
float3 prand3(float2, float2);
float2 prand2(float2, float2);
float prand(float2, float2);

float3 interporand(float2 pos, float reso = 256);

void neighborhood(texture2d<float> t, uint2 xco, thread float3 uv[9]);
// void neighborhood(texture2d<float> t, uint2 xco, float3 uv[5]);
void neighborhood(texture2d<float> t, uint2 xco, thread float3x3 op[4]);

float convolve(float3x3 a, float3x3 b);

// ================================================================================
// Useful utilities
// ================================================================================

using namespace global;

template <typename T>
static
T saw(T x) {
  return 1 - abs( tau - 2 * fmod(abs(x), tau)) / tau;
}

// equivalent to:
//  (acos(cos(x))/PI) if x is divided by Pi

float3 flux(float x);
float cross( float2 a, float2 b );
float3 phase(float map);

float3 tex3d( const texture2d<float> tex, const float3 pp, const float3 nn );
float3 doBumpMap(const texture2d<float> txx, const float3 p, const float3 n, float bf);

float getAudio(device float *a, float x);
float getFft(device float *a, float x);


float polySmin( float a, float b, float k );
float polySmax( float a, float b, float k );
float expSmin(float a, float b, float k);
float expSmax(float a, float b, float k);
float commSmin(float a, float b, float k);
float commSmax(float a, float b, float k);

float2 PixToHex(float2 p);
float2 HexToPix(float2 h);
float3 HexGrid (float2 p);
float HexEdgeDist(float2 p);

float3 blackbody(float Temp);
float3 BlackBody( float t);

// ============================================

float noisePerlin(float  x);
float noisePerlin(float2 x);
float noisePerlin(float3 x);

float4 hash4( float n);

// -----------------------------------------------
// Colors

typedef float3 Color;

Color palette( float t, Color a, Color b, Color c, Color d );

float vignette( float2 uv, float p);

// Normalized Device Coordinate given Viewport coordinate and Viewport size

float2 yflip(float2 x);

float2 ndc(float2 vc, float2 res);

// convert texture coordinates to world coordinates
float2 toWorld(float2 x);

float4x4 translation(float x, float y, float z);
float4x4 scale(float x, float y, float z);
float4x4 perspective(float aspect, float fovy, float near, float far);

#endif /* support_h */
