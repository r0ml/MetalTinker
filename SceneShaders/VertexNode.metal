
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>


// FIXME: what am I doing here?

#define shaderName Arcs

#include "Common.h"

/*
struct PlaneNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
    float2x3 boundingBox;
};
*/

/*
typedef struct {
    float3 position     [[ attribute(SCNVertexSemanticPosition) ]];
    float2 texCoords    [[ attribute(SCNVertexSemanticTexcoord0) ]];
  float4 color [[attribute(SCNVertexSemanticColor) ]];
  float3 normal [[ attribute(SCNVertexSemanticNormal) ]];

} VertexInput;
*/

/*
struct vertexOutput
{
    float4 position [[position]];   // clip space
    float2 texCoords;
};*/

/*
struct VertexOut {
  float4  where [[position]];   // this is in the range -1 -> 1 in the vertex shader,  0 -> viewSize in the fragment shader
  float4  color;
  float2 texCoords;
  float3 normal;
};
*/
/*
typedef struct {
  float4x4 modelTransform;
  float4x4 inverseModelTransform;
  float4x4 modelViewTransform;
  float4x4 inverseModelViewTransform;
  float4x4 normalTransform; // Inverse transpose of modelViewTransform
  float4x4 modelViewProjectionTransform;
  float4x4 inverseModelViewProjectionTransform;
  float2x3 boundingBox;
  float2x3 worldBoundingBox;
} PerNodeData;
*/

// We will not be using the values encapuslated in SCNSceneBuffer
/*
vertex VertexOut
vertex_function(VertexInput                 in          [[ stage_in ]],
                constant SCNSceneBuffer&    scn_frame   [[buffer(0)]],
                constant PerNodeData&   scn_node    [[buffer(1)]])
{
    VertexOut vert;
  // float4 z = scn_frame.viewportSize;

  vert.where = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    // Pass the texture coords to fragment function.
    vert.texCoords = in.texCoords;


  // SceneBuffer has viewportSize ---- ?

    return vert;
}
*/

 constant const int arcSides = 25;

 struct InputBuffer {
   float4 clearColor = 0;
   struct {
     int4 _1;
   } pipeline;
     float3 radius;
     float3 thickness;
 };

 initialize() {
   in.pipeline._1 = {3, 6 * arcSides, 3, 1};

   in.clearColor = {0, 0, 0, 1};
   in.thickness = { 0.01, 0.05, 0.1};
   in.radius = {0.2, 0.3, 0.5};
 }



vertexFn(constant float &thickness, constant float &radius, constant int &arcid) {
  VertexOut v;

//  float thickness = 0.05;
//  float radius = 0.3;

//  float2 w = annulus(vid, arcSides, in.radius.y - in.thickness.y / 2, in.radius.y + in.thickness.y / 2,
  float2 w = annulus(vid, arcSides, radius - thickness / 2, radius + thickness / 2,
                     arcid * PI/4, (arcid + 1) * PI/4);

//  a.xy = (a.xy * aspect * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.))) / aspect;

  v.where = scn_node.modelViewProjectionTransform * float4(w, 0, 1);

//  v.where = float4(w, 0, 1);
  // v.where.zw = {0, 1};

  // v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  // v.texCoords = scn_node.

  v.color = {0.5 + 0.2 * (arcid == 1), 0.5, 0.5 + 0.2 * (arcid == 2), 1};
//  v.color = 1;
//  v.color = color;
  return v;
}

 fragmentFn() {
   return thisVertex.color;
}
