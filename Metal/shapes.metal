// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#define shaderName not_used
#include "Common.h"

#include <metal_stdlib>
using namespace metal;

// Vertex fn...

// this is a radial way of creating polygons -- at around 50 sides it's a circle
float2 polygon(uint vid, uint sides, float radius) {
  uint tv = vid % 3;
  uint tn = vid / 3;
  float2 res = 0;
  float z = 0;
  switch(tv) {
    case 0:
      z = (float(tn) + 0.5) / float(sides);
      break;
    case 1:
      z = float(tn) / float(sides);
      res.xy = float2(radius, 0) * rot2d( z * TAU );
      break;
    case 2:
      z = float(tn + 1) / float(sides);
      res.xy = float2(radius, 0) * rot2d( z * TAU );
      break;
  }
  return res;
}

// centered at 0
/*float2 annulus(uint vid, uint sides, float inner, float outer, float2 aspect) {
  uint tv = vid % 6;
  uint tn = vid / 6;
  float2 res = 0;
  float z = 0;
  switch(tv) {
    case 0:
    case 4:
      z = 2 * float(tn + 0.5) / float(sides);
      res.xy = float2(outer, 0) * aspect * rot2d(z * TAU) / aspect;
      break;
    case 1:
      z = 2 * float(tn)     / float(sides); // this one is negative for tn = 0
      res.xy = float2(inner, 0) * aspect * rot2d( z * TAU ) / aspect;
      break;
    case 2:
    case 3:
      z = 2 * float(tn + 1) / float(sides);
      res.xy = float2(inner, 0) * aspect * rot2d( z * TAU) / aspect;
      break;
    case 5:
      z = 2 * float(tn + 1.5) / float(sides);
      res.xy = float2(outer, 0) * aspect * rot2d( z * TAU ) / aspect;
      break;
  }
  return res;
}*/


// centered at 0
float2 annulus(uint vid, uint sides, float inner, float outer, float startAngle, float endAngle) {
  uint tv = vid % 6;
  uint tn = vid / 6;
  float tnx;
  float2 res = 0;
  float z = 0;
  float subtend = endAngle - startAngle; // in radians -- default is TAU
  float dem = sides;

  if (tn == dem) { return 0; }

  switch(tv) {
    case 0:
    case 4:
      tnx = tn + 0.5 * (tn != 0);
      z = startAngle + tnx / dem * subtend;
      res.xy = float2(outer, 0) * rot2d(z);
      break;
    case 1:
      z = startAngle + float(tn) / dem * subtend; // this one is negative for tn = 0
      res.xy = float2(inner, 0) * rot2d( z);
      break;
    case 2:
    case 3:
      tnx = float(tn + 1);
      z = startAngle + tnx / dem * subtend;
      res.xy = float2(inner, 0) * rot2d( z );
      break;
    case 5:
      tnx = tn + 1.5 - 0.5 * (tn == dem - 1);
      z = startAngle + tnx / dem * subtend;
      res.xy = float2(outer, 0) * rot2d( z );
      break;
  }
  return res;
}


