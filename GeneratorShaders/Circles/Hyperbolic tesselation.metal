
#define shaderName Hyperbolic_tesselation

#include "Common.h"

static float2 conj(float2 a) {
  return float2(a.x, -a.y);
}

static float2 mul(float2 a, float2 b) {
  return float2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

static float2 expo(float2 a) {
  float l = exp(a.x);
  return l*float2(cos(a.y), sin(a.y));
}

static float abs_sq(float2 xy) {
  return xy.x*xy.x + xy.y*xy.y;
}

static float2 invert(float2 xy) {
  float a = abs_sq(xy);
  return (1./a)*conj(xy);
}

static float2 doshift(float2 z, float2 a) {
  return mul(z - a, invert(float2(1, 0) - mul(conj(a), z)));
}

fragmentFunc() {
  float l = 1./3.*sqrt(3.);
  float halfl;
  int dcount=0;

  int sides = 4;

  float t = 0.;

  halfl = (1. - sqrt(1. - l*l))/l;
//  thisVertex.where.xy.xy -= max(float2(0), uni.iResolution.xy - uni.iResolution.yx)/2.;
//  thisVertex.where.xy = thisVertex.where.xy / min(uni.iResolution.x, uni.iResolution.y);
//  thisVertex.where.xy = thisVertex.where.xy*2. - float2(1,1);
  
  t = scn_frame.time * 1.4;
  float2 pos = worldCoordAdjusted;
  
  pos = 1.05*pos;
  if (abs_sq(pos) >= 1.) return float4(0.5, 0.5, 0.5, 0.5);
  //if (abs_sq(pos) <= 0.0002) return float4(1, 0, 0, 1);
  //pos = transform(pos);
  int col = dcount;
  
  float2 rv = expo(float2(0, PI*2./float(sides)));
  float2 dv = float2(l, 0);
  int ctr = 0;
  int flipctr = 0;
  for (int i=0; i<=20; i++) {
    dv = mul(dv, rv);
    float2 newpos = doshift(pos, dv);
    if (abs_sq(newpos) >= abs_sq(pos)) {
      ctr++;
      if (ctr >= sides) break;
    } else {
      ctr = 0;
      pos = -newpos;
      if (i%2 == 0) flipctr++;
      col++;
    }
  }
  
  if ((col + flipctr) % 2 == 0) pos.x *= -1.;
  if (flipctr % 2 == 0) pos.y *= -1.;
  
  float shift = mod(t, 8.);
  if (shift >= 4.) {
    shift -= 4.;
    //pos = -pos;
  }
  if (shift >= 2.) {
    shift -= 2.;
    pos = float2(pos.y, -pos.x);
    col++;
  }
  shift = 1. - cos(shift * PI * .5);
  shift -= 1.; shift *= halfl;
  pos = doshift(pos, float2(halfl, 0));
  pos = doshift(pos, float2(shift, 0));
  float2 newpos = doshift(pos, float2(-l, 0));
  if (abs_sq(newpos) < abs_sq(pos)) {
    col++;
    pos = newpos;
  }
  
  float4 backgtiles = float4(float3(col%2), 1);
  float4 thecolor = float4(0,0,0,1);
  if (abs_sq(pos) <= halfl*halfl*0.5) thecolor.rgb = float3(1, 1, 1);
  
  return 0.9*thecolor + 0.1*backgtiles;
}

