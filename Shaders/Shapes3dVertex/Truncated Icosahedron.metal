
#define shaderName truncated_icosahedron

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
  in.pipeline._1 = { 3, 348, 1, 0 };
}

// vertex indices of each face
constant int truncated_icosahedron_pentagons[12][5] = {
  {0, 36, 12, 16, 40},
  {1, 41, 17, 13, 37},
  {2, 42, 18, 14, 38},
  {3, 39, 15, 19, 43},
  {4, 44, 20, 24, 48},
  {5, 49, 25, 21, 45},
  {6, 50, 26, 22, 46},
  {7, 47, 23, 27, 51},
  {8, 52, 28, 32, 56},
  {9, 57, 33, 29, 53},
  {10, 58, 34, 30, 54},
  {11, 55, 31, 35, 59},
};
  
constant int truncated_icosahedron_hexagons[20][6] = {
  { 0,  2, 38, 32, 28, 36 },
  { 0, 40, 29, 33, 42,  2 },
  { 1,  3, 43, 35, 31, 41 },
  { 1, 37, 30, 34, 39,  3 },
  
  { 4,  6, 46, 16, 12, 44 },
  { 4, 48, 13, 17, 50,  6 },
  { 5,  7, 51, 19, 15, 49 },
  { 5, 45, 14, 18, 47,  7 },
  
  { 8, 10, 54, 24, 20, 52 },
  { 8, 56, 21, 25, 58, 10 },
  { 9, 53, 22, 26, 55, 11 },
  { 9, 11, 59, 27, 23, 57 },
  
  { 12, 36, 28, 52, 20, 44 },
  { 13, 48, 24, 54, 30, 37 },
  { 14, 45, 21, 56, 32, 38 },
  { 15, 39, 34, 58, 25, 49 },
  
  { 16, 46, 22, 53, 29, 40 },
  { 17, 41, 31, 55, 26, 50 },
  { 18, 42, 33, 57, 23, 47 },
  { 19, 51, 27, 59, 35, 43 },
};

vertexPass(_1) {
  VertexOut v;
  v.color = float4(0.7, 0.8, 0.9, 1);
  v.where.w = 1;
  
  float aspect = uni.iResolution.x / uni.iResolution.y;
  
  int ph = vid < 108;

  float3 truncated_icosahedron[60] = {
    { 0,  1,  3 * PHI },
    { 0,  1, -3 * PHI },
    { 0, -1,  3 * PHI },
    { 0, -1, -3 * PHI },
    
    {  1,  3 * PHI, 0 },
    {  1, -3 * PHI, 0 },
    { -1,  3 * PHI, 0 },
    { -1, -3 * PHI, 0 },
    
    {  3 * PHI, 0,  1 },
    { -3 * PHI, 0,  1 },
    {  3 * PHI, 0, -1 },
    { -3 * PHI, 0, -1 },
    
    { 1,    2 + PHI,   2 * PHI },
    { 1,    2 + PHI,  -2 * PHI },
    { 1, - (2 + PHI),  2 * PHI },
    { 1, - (2 + PHI), -2 * PHI },
    {-1,    2 + PHI,   2 * PHI },
    {-1,    2 + PHI,  -2 * PHI },
    {-1, - (2 + PHI),  2 * PHI },
    {-1, - (2 + PHI), -2 * PHI },

    {    2 + PHI,   2 * PHI,  1 },
    {    2 + PHI,  -2 * PHI,  1 },
    { - (2 + PHI),  2 * PHI,  1 },
    { - (2 + PHI), -2 * PHI,  1 },
    {    2 + PHI,   2 * PHI, -1 },
    {    2 + PHI,  -2 * PHI, -1 },
    { - (2 + PHI),  2 * PHI, -1 },
    { - (2 + PHI), -2 * PHI, -1 },

    {  2 * PHI,  1,    2 + PHI },
    { -2 * PHI,  1,    2 + PHI },
    {  2 * PHI,  1, - (2 + PHI) },
    { -2 * PHI,  1, - (2 + PHI) },
    {  2 * PHI, -1,    2 + PHI },
    { -2 * PHI, -1,    2 + PHI },
    {  2 * PHI, -1, - (2 + PHI) },
    { -2 * PHI, -1, - (2 + PHI) },

    {  PHI,  2,   1 + 2 * PHI  },
    {  PHI,  2, -(1 + 2 * PHI) },
    {  PHI, -2,   1 + 2 * PHI  },
    {  PHI, -2, -(1 + 2 * PHI) },
    { -PHI,  2,   1 + 2 * PHI  },
    { -PHI,  2, -(1 + 2 * PHI) },
    { -PHI, -2,   1 + 2 * PHI  },
    { -PHI, -2, -(1 + 2 * PHI) },

    {  2,   1 + 2 * PHI ,  PHI },
    {  2, -(1 + 2 * PHI),  PHI },
    { -2,   1 + 2 * PHI ,  PHI },
    { -2, -(1 + 2 * PHI),  PHI },
    {  2,   1 + 2 * PHI , -PHI },
    {  2, -(1 + 2 * PHI), -PHI },
    { -2,   1 + 2 * PHI , -PHI },
    { -2, -(1 + 2 * PHI), -PHI },

    {    1 + 2 * PHI ,  PHI,  2 },
    {  -(1 + 2 * PHI),  PHI,  2 },
    {    1 + 2 * PHI ,  PHI, -2 },
    {  -(1 + 2 * PHI),  PHI, -2 },
    {    1 + 2 * PHI , -PHI,  2 },
    {  -(1 + 2 * PHI), -PHI,  2 },
    {    1 + 2 * PHI , -PHI, -2 },
    {  -(1 + 2 * PHI), -PHI, -2 }
    
  };

  if (ph) {
    int face = vid / 9;
    int p = vid % 9;    // which point within the 5 of the pentagon
    // map is  0 1 2 -> 0 1 2,  3 4 5 -> 0 2 3, 6 7 8 -> 0 3 4
    const int pgp[9] = { 0, 1, 2, 0, 2, 3, 0, 3, 4 };
    int vn = truncated_icosahedron_pentagons[face] [pgp [p]] ;
    float3 vx = truncated_icosahedron[ vn ];
    v.where.xyz = 2 * vx - 1;
    v.color = { 0.1, 0.1, 0.1, 1};
  } else {
    int face = (vid - 108)/ 12;
    int p = vid % 12; // which point within the 6 of the hexagon
    // map is 0 1 2 -> 0 1 2, 3 4 5 -> 0 2 3, 6 7 8 -> 0 3 4, 9 10 11 -> 0 4 5
    const int pgp[12] = { 0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5 };
    int vn = truncated_icosahedron_hexagons[face] [pgp [p]];
    float3 vx = truncated_icosahedron[ vn];
    v.where.xyz = 2 * vx - 1;
  }

  v.where.xyz *= 0.1;
  v.where.x /= aspect;
  
  return v;
}

    /*

const float3 light_dir = float3( -0.7, 0.7, -0.14 );
const float focalLength = 4.0;
const float cameraDistance = 5.0;

float3 getNormal(int i) {
  int block = i / 4;
  float3 signs = sign(float3(i & int3(4, 2, 1)) - 0.1);

  if (block > 5) {
    return 0.5774 * signs;
  }

  float3 r = signs * (block < 3 ? float3(0.0, 0.5257, 0.8507) : float3(0.0, 0.9342, 0.3568));
  return float3(r[block % 3], r[(block + 2) % 3], r[(block + 1) % 3]);
}

float2x2 rotationMatrix(float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return float2x2(c, -s, s, c);
}

float fragmentx(float3 L, float3 N, float3 V) {
  float ambient = 0.1;
  float diffuse = 0.5 + 0.5 * dot(L, N);
  float3 R = reflect(-L, N);
  float specular = pow(max(0.0, dot(R, V)), 2.0);
  return ambient + 0.8 * diffuse + 0.3 * specular;
}

float getColor(float2 thisVertex.where.xy) {
  float2 uv = (2.0 * thisVertex.where.xy - uni.iResolution.xy) / uni.iResolution.y;
  float3 viewDir = normalize(float3(uv.xy, focalLength));
  float2x2 rotation = rotationMatrix(uni.iTime);

  float z_back = 1e8;
  float z_front = 0.0;
  float3 result_normal;

  for (int i = 0; i < 32; i++) {
    float3 normal = getNormal(i);
    normal.xz = rotation * normal.xz;
    float dist = i < 12 ? 1.0 : 0.975;

    float viewDirDotNormal = dot(viewDir, normal);
    float z = (dist + normal.z * cameraDistance) / viewDirDotNormal;
    bool front = viewDirDotNormal < 0.0;
    if (front && z > z_front) {
      result_normal = normal;
      z_front = z;
    }
    if (!front && z < z_back) {
      z_back = z;
    }
  }

  return z_front > z_back ? 0.0 : fragmentx(light_dir, result_normal, -viewDir);
}

fragmentFn() {
  fragColor = float4(getColor(thisVertex.where.xy));
}

*/
