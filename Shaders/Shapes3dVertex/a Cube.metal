
#define shaderName a_Cube

#include "Common.h" 

// if I have many more parameters for a render pass, I'll need a structure
// a possible additional parameter is "render pass output".  This would be the integer that identifies which render pass texture to use
//      as the output of the render pass, which could be referenced by subsequent passes.
// also, the pipeline could include a "compute pass" -- which is inserted between the vertex shader and the fragment shader?  In this case,
//      instead of vertex count, instance count -- the parameters are the width and height of the array?

struct InputBuffer {
  struct {
    int3 _1 = {4, 4, 1}; // triangleStrip, vertex count, instance count
    int3 _2 = {3, 36, 1}; // triangles, vertex count, instance count
  } pipeline;
};

initialize() {
  in.pipeline._1 = {4, 4, 1};
  in.pipeline._2 = {3, 36, 1};
}

fragmentPass(_1) {
  return float4( textureCoord, 0, 1); // this is the background?
}

// this is as a triangle strip.   But for vertex shading, I want triangles.
/*
 static constant float3 cube_strip[14] = {
  { 0, 1, 1 },     // Front-top-left
  { 1, 1, 1 },      // Front-top-right
  { 0, 0, 1 },    // Front-bottom-left
  { 1, 0, 1 },     // Front-bottom-right
  { 1, 0, 0 },    // Back-bottom-right
  { 1, 1, 1 },      // Front-top-right
  { 1, 1, 0 },     // Back-top-right
  { 0, 1, 1 },     // Front-top-left
  { 0, 1, 0 },    // Back-top-left
  { 0, 0, 1 },    // Front-bottom-left
  { 0, 0, 0 },   // Back-bottom-left
  { 1, 0, 0 },    // Back-bottom-right
  { 0, 1, 0 },    // Back-top-left
  { 1, 1, 0 }      // Back-top-right
};
*/

// this is as a triangles.   But for vertex shading, I want triangles.
static constant float3 cube_triangles[36] = {
  // front face
  { 0, 1, 1 },     // Front-top-left
  { 1, 1, 1 },      // Front-top-right
  { 0, 0, 1 },    // Front-bottom-left
  
  { 1, 1, 1 },
  { 0, 0, 1 },
  { 1, 0, 1 },     // Front-bottom-right
  
  // bottom face
  { 0, 0, 1 },
  { 1, 0, 1 },     // Front-bottom-right
  { 1, 0, 0 },    // Back-bottom-right
  
  { 0, 0, 1 },    // Front-bottom-left
  { 0, 0, 0 },    // Back-bottom-left
  { 1, 0, 0 },    // Back-bottom-right
  
  // right face
  { 1, 0, 1 },     // Front-bottom-right
  { 1, 0, 0 },    // Back-bottom-right
  { 1, 1, 1 },      // Front-top-right
  
  { 1, 0, 0 },    // Back-bottom-right
  { 1, 1, 1 },      // Front-top-right
  { 1, 1, 0 },     // Back-top-right
  
  // top face
  { 1, 1, 1 },      // Front-top-right
  { 1, 1, 0 },     // Back-top-right
  { 0, 1, 1 },     // Front-top-left
  
  { 1, 1, 0 },     // Back-top-right
  { 0, 1, 1 },     // Front-top-left
  { 0, 1, 0 },    // Back-top-left
  
  // left face
  { 0, 1, 1 },     // Front-top-left
  { 0, 1, 0 },    // Back-top-left
  { 0, 0, 1 },    // Front-bottom-left
  
  { 0, 1, 0 },    // Back-top-left
  { 0, 0, 1 },    // Front-bottom-left
  { 0, 0, 0 },   // Back-bottom-left
  
  // back face
  { 0, 0, 0 },
  { 1, 0, 0 },    // Back-bottom-right
  { 0, 1, 0 },    // Back-top-left
  
  { 1, 0, 0 },    // Back-bottom-right
  { 0, 1, 0 },    // Back-top-left
  { 1, 1, 0 }      // Back-top-right
};

vertexPass(_2) {
  VertexOut v;
  float3 p = 0.4 + cube_triangles[vid] * 0.2;
  
  float2 aspect = uni.iResolution / uni.iResolution.x;
  
  p = p - 0.5; // centered
  
  p.x = p.x * aspect.y;
  p.z = p.z * 0.5;
  
  p.y = p.y * aspect.y;
  //  p.z = p.z * 0.5;
  float2x2 r = rot2d(uni.iTime);
  p.xy = p.xy * r;
  p.yz = p.yz * r;
  p.xz = p.xz * r;
  p.y = p.y / aspect.y;
  //  p.z = p.z / 0.5;
  
  
  p += 0.5;  // recentered
  
  v.where.xy = 2 * p.xy - 1;
  v.where.z = p
  .z;
  v.where.w = 1;
  
  v.color = { 0.5 + ( ( (35 - vid) / 6)/ 6.0), 0.5 + ( (vid / 6)/ 6.0), 0.5, 1}; // then it works like it used to....
  return v;
  
}

/*
static float dist(float3 p, float time) {
  float2x2 r = rot2d(time);
  p.xy = p.xy * r;
  p.yz = p.yz * r;
  p.xz = p.xz * r;
  float3 delta = abs(p) - 0.6;
  return length(max(delta, 0.0));
}
*/

/*
fragmentFn() {
  float2 uv = worldCoordAspectAdjusted;
  
  float3 d = normalize(float3(uv, -1.0));
  float3 p = float3(uv, 1.0);
  float3 o = p;
  int i=0;
  float dst;
  for(i=0; i<60; i++) {
    dst = dist(p, uni.iTime);
    if(dst < 0.01) {
      break;
    }
    p += dst*d;
  }
  if(dst < 0.1) {
    return float4(length(p-o)*0.5);
  } else {
    return float4(uv, 0.0, 1);
  }
}
*/
