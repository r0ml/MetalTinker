
#define shaderName Basic_Orbit

#include "Common.h"

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  in.pipeline._1 = {3, 150, 1, 0};
}

/*
// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: float3) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}
*/


vertexPass(_1) {
  float radius = 0.1;
  VertexOut v;
  v.where.xy = polygon(vid, in.pipeline._1.y / 3, radius);
  v.where.zw = {0, 1};
  v.color = {0.4, 0.5, 0.6, 1};

  float3 ctr = float3(sin(uni.iTime), 0,  (1 + cos(uni.iTime) ) ) ;
  v.where.xyz = v.where.xyz + ctr;

  float aspect = uni.iResolution.x / uni.iResolution.y;
  float fov = PI / 4;
  float near = 0.001;
  float far = 4;

  float4x4 mv = translation(0, 0, -4);
  float4x4 pm = perspective(aspect, fov, near, far);

  v.where = pm * mv * v.where;
  return v;
}

