
#define shaderName an_Icosahedron

#include "Common.h"

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
};

initialize() {
  // it's 60 vertices, 12 pentagons, 20 hexagons.
  // each pentagon can be represented by 3 triangles (9 vertices)
  // each hexagon can be represnted by 4 triangles (12 vertices)
  // so the triangular mesh contains 3 * 12 + 4 * 20 = 116 triangles = 348 vertices
  in.pipeline._1 = { 3, 60, 1, 0 };
}

// this calculates the 12 icosahedron vertices.
static float3 icovert(int n) {
  float a = (2 * ( (n % 4) % 2) - 1); // -1 1 -1 1
  float b = (2 * ((n % 4) < 2) - 1) * PHI; // PHI PHI -PHI -PHI
  float3 res = 0;
  res[n/4] = a;
  res[(1+n/4) % 3] = b;
  return res;
}

constant const int3 faces[20] = {
  {0, 11, 5 },
  {0,  5, 1 },
  {0,  1, 7 },
  {0,  7, 10},
  {0, 10, 11},

  {  1, 5, 9},
  {  5, 11, 4},
  { 11, 10, 2},
  { 10, 7 , 6},
  {  7, 1, 8},

  {3, 9, 4},
  {3, 4, 2},
  {3, 2, 6},
  {3, 6, 8},
  {3, 8, 9},

  {4, 9, 5},
  {2, 4, 11},
  {6, 2, 10},
  {8, 6, 7},
  {9, 8, 1}
};

// there are 20 faces, so 60 verticse taken from the set of 12
static float3 icosahedron(int vid) {
  int a = vid / 3;
  int b = vid % 3;
  return icovert(faces[a][b]);
}

vertexPass(_1) {
  VertexOut v;
  v.color.rgb = float3(0.7, 0.8, 0.9) * ((vid / 3) / 20.0);
  v.color.a = 1;
  v.where.w = 1;
  v.where.xyz = icosahedron(vid) / 2;
  return v;
}
