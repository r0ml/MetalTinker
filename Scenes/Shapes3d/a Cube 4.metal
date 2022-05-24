
#define shaderName a_Cube_4

#include "Common.h"
struct InputBuffer {  };
initialize() {}

/*
 *	Basic Raymarch / Distance field shader
 */

/*
 *	Basic Rotation matrices
 */

/*static float3x3 rotateX(float a) {
  return float3x3(
                  1.0, 0.0, 0.0,
                  0.0, cos(a), sin(a),
                  0.0, -sin(a), cos(a)
                  );
}*/

static float3x3 rotateY(float a) {
  return float3x3(
                  cos(a), 0.0, sin(a),
                  0.0, 1.0, 0.0,
                  -sin(a), 0.0, cos(a)
                  );
}

static float3x3 rotateZ(float a) {
  return float3x3(
                  cos(a), sin(a), 0.0,
                  -sin(a), cos(a), 0.0,
                  0.0, 0.0, 1.0
                  );
}

/*
 *	Signed Distance Functions
 */

/*static float sphere_sdf(float3 p) {
  return length(p) - 1.0;
}*/

static float cube_sdf(float3 p) {
  return length(max(abs(p)- float3(0.5, 0.5, 0.5),0.0));
}
/*
static float torus_sdf(float3 p) {
  float2 q = float2(length(p.xz) - 0.9, p.y);
  return length(q) - 0.1;
}*/

/*
 *	Raymarch / trace function
 */

static float trace(float3 o, float3 r, float3x3 tf) {
  float t = 0.0;
  for (int i = 0; i < 32; i++) {
    float3 p = o + r * t;
    float d = cube_sdf(tf * p);
    t += d * 0.5;
  }
  return t;
}

fragmentFn() {
  
  float time = uni.iTime;
  
  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  uv = uv * 2.0 - 1.0;
  uv *= float2(uni.iResolution.x / uni.iResolution.y, 1.0);
  
  float3 p = float3(uv, 0.0) + float3(0.0, 0.0, 1.0);
  
  float3 l = float3(uv, 0.0) + float3(uni.iMouse.x * 4.0 - 2.0, uni.iMouse.y * 4.0 - 2., 3.0);
  float3 n = normalize(p);
  
  float3 lp = normalize(l - p);
  float3 lc = float3(dot(lp, n));
  float3 color = float3(1.0, 0.0, 0.0);
  
  float3 r = normalize(p);
  float3 o = float3(0.0, 0.0, -3.0);
  
  float t = trace(o, r, rotateZ(time) * rotateY(time));
  
  float fog = 1.0 / (1.0 + t * t * 0.1);
  
  color.b *= fog;
  float3 fc = float3(fog * lc * color);
  
  return float4(fc, 1.0);
  
}
