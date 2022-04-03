
#define shaderName Blend

#include "Common.h" 

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = 6;
  ctrl.instanceCount = 3;

  // ctrl.blend = true
}

static constant float2 square_triangles[6] = {
  // front face
  { 0, 1 },     // Front-top-left
  { 1, 1 },      // Front-top-right
  { 0, 0 },    // Front-bottom-left
  
  { 1, 1 },
  { 0, 0 },
  { 1, 0 }     // Front-bottom-right
};

vertexFn() {
  VertexOut v;
  v.color = 0;
  v.color[iid] = 1;  // color based on instance
  v.color.w = 1;
  v.where.z = 0;
  v.where.w = 1;
  
  float aspect = uni.iResolution.x / uni.iResolution.y;
  float2 offset[3] = { float2(0, 0.2), float2(-0.2, -0.2), float2(0.2, -0.2) } ;
  v.where.xy = 2 * square_triangles[vid] - 1;
  v.where.xy *= float2(0.3, aspect * 0.3) ;
  v.where.xy += offset[iid];

  return v;
}

/*

 
float K(float a, float b) {
  return length(pow(abs(thisVertex.where.xy/uni.iResolution.y/.5 + float2(a, b)-1.), float2(sin(uni.iTime * 0.5) * 1.5 + 1.8)));
}

fragmentFn() {
  fragColor = smoothstep(1., .4, float4( K(-.78,-.25), K(-.48, .25), K(-1.08, .25), 1)/.5);
  fragColor.w = 1;
}

*/

