// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct PlaneNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
    float2x3 boundingBox;
};

typedef struct {
    float3 position     [[ attribute(SCNVertexSemanticPosition) ]];
    float2 texCoords    [[ attribute(SCNVertexSemanticTexcoord0) ]];
  float4 color [[attribute(SCNVertexSemanticColor) ]];
  float3 normal [[ attribute(SCNVertexSemanticNormal) ]];
  
} VertexInput;

/*
struct vertexOutput
{
    float4 position [[position]];   // clip space
    float2 texCoords;
};*/

struct VertexOut {
  float4  where [[position]];   // this is in the range -1 -> 1 in the vertex shader,  0 -> viewSize in the fragment shader
  float4  color;
  float2 texCoords;
  float3 normal;
};

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

// We will not be using the values encapuslated in SCNSceneBuffer
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

/*
fragment half4
fragment_function(vertexOutput                      interpolated    [[stage_in]],
                  texture2d<float, access::sample>  diffuseTexture  [[texture(0)]])
{
    constexpr sampler sampler2d(coord::normalized,
                                filter::linear, address::repeat);
    float4 color = diffuseTexture.sample(sampler2d,
                                         interpolated.texCoords);
    return half4(color);

}

// Generate a texture.
void kernel kernel_function(uint2                           gid         [[ thread_position_in_grid ]],
                            texture2d<float, access::write> outTexture  [[texture(0)]])
{
    // Check if the pixel is within the bounds of the output texture
    if ((gid.x >= outTexture.get_width()) ||
        (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    float2 textureSize = float2(outTexture.get_width(),
                                outTexture.get_height());
    float2 position = float2(gid);
    float4 pixelColor = float4(position/textureSize, 0.0, 1.0);
    pixelColor.y = 1.0 - pixelColor.y;  // invert the green component.
    outTexture.write(pixelColor, gid);
}
*/
