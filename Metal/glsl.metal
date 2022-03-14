
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#include "glsl.h"

float normalize(float n) {
  return n / MAXFLOAT;
  // alternatively, this always returns 1.0
}

int packSnorm2x16(float2 c) {
  uint2 a = uint2(round(clamp(c, -1.0, 1.0) * 32767.0));
  return (a.x << 16) | (a.y);
}

uint packUnorm2x16(float2 c) {
  uint2 a = uint2(round(clamp(c, 0., 1.0) * 65536.0));
  return (a.x << 16) | (a.y);
}

float2 unpackSnorm2x16(int c) {
  int f1 = 32768 - (c & 0xffff);
  int f2 = c >> 16;
  return float2(clamp(f2 / 32768.0, -1.0, 1.0), clamp(f1 / 32768.0, -1.0, 1.0));
}

float2 unpackUnorm2x16(int c) {
  uint f1 = (c & 0xffff);
  uint f2 = (c >> 16) & 0xffff;
  return float2(clamp(f2 / 65536.0, 0., 1.0), clamp(f1 / 65536.0, 0. , 1.));
}

float4 textureLod(texture2d<float> tx, sampler s, float2 p, float l ) {
  // FIXME:  this is WRONG
  return tx.sample(s, p, level(l) );
}

float4 textureLod(texturecube<float> tx, sampler s, float3 p, float l ) {
  return tx.sample(s, p, level(l));
}

float4 textureGrad(texture2d<float> tx, sampler s, float2 p, float2 x, float2 y ) {
  return tx.sample(s, p, gradient2d(x, y) );
}

float4 texelFetch(texture2d<float> tx, int2 p, int lod) {
  return tx.read(uint2(p), lod);
}

float4 texelFetch(texture2d<float> tx, uint2 p, uint lod) {
  return tx.read(p, lod);
}

float4 texelFetch(texture1d<float> tx, uint p) {
  return tx.read(p, 0);
}

float distance(float x, float y) {
  return abs(x-y);
}

float4x4 inverse(float4x4 mm) {
  float4x4 om = float4x4(1);
  int rows = 4;
  for(int i = 0; i < rows; i++) {
    // for(int j = i; j < rows; j++) {
    // if abs(mm[j][j]) < epsilon {
    //  float3 v = mm[i];
    //
    // }
    float n = 1. / mm[i][i];
    om[i] *= n;
    mm[i] *= n;
    for(int j=i+1;j<rows;++j) {
      float t = mm[j][i];
      mm[j] -= mm[i] * t;
      om[j] -= om[i] * t;
      mm[j][i]=0; //not necessary, but looks nicer than 10^-15
    }
  }
  // solving a triangular matrix
  for(int i=rows-1;i>0;--i) {
    for(int j=i-1;j>=0;--j) {
      float t = mm[j][i];
      om[j] -= om[i] * t;
      mm[j] -= mm[i] * t;
    }
  }
  return om;
}

float4x4 mat3to4(float3x3 mm) {
  return float4x4(mm[0][0], mm[0][1], mm[0][2], 0, mm[1][0], mm[1][1], mm[1][2], 0, mm[2][0],mm[2][1],mm[2][2], 0, 0, 0, 0, 0);
}

float3x3 inverse(float3x3 mm) {
  float3x3 om = float3x3(1);
  int rows = 3;
  for(int i = 0; i < rows; i++) {
    // for(int j = i; j < rows; j++) {
    // if abs(mm[j][j]) < epsilon {
    //  float3 v = mm[i];
    //
    // }
    float n = 1. / mm[i][i];
    om[i] *= n;
    mm[i] *= n;
    for(int j=i+1;j<rows;++j) {
      float t = mm[j][i];
      mm[j] -= mm[i] * t;
      om[j] -= om[i] * t;
      mm[j][i]=0; //not necessary, but looks nicer than 10^-15
    }
  }
  // solving a triangular matrix
  for(int i=rows-1;i>0;--i) {
    for(int j=i-1;j>=0;--j) {
      float t = mm[j][i];
      om[j] -= om[i] * t;
      mm[j] -= mm[i] * t;
    }
  }
  return om;
}

float2x2 inverse(float2x2 mm) {
  float d = determinant(mm);
  return float2x2(mm[1][1]/d, -mm[0][1]/d, -mm[1][0]/d, mm[0][0]/d);
}

float dot(float a, float b) {
  return a * b;
}

