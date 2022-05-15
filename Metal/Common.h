
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

#ifndef Common_h
#define Common_h

constant int uniformId = 2;
constant int kbuffId = 3;
constant int inputTextureId = 0;
constant int computeBuffId = 15;
constant int ctrlBuffId = 4;

struct string { char name[256]; } ;

using namespace metal;

namespace apprender {

}
struct VertexOut {
  float4 where [[position]];   // this is in the range -1 -> 1 in the vertex shader,  0 -> viewSize in the fragment shader
  float4 color;
  float2 texCoords;
  float3 normal;
};

struct VertexOutPoint {
  float4  where [[position]];
  float4  color;
  float point_size [[point_size]]; // only for pointcloud
};

#include "support.h"
#include "sdf.h"
#include "constants.h"
#include "glsl.h"
#include "shapes.h"
#include <SceneKit/scn_metal>

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

#ifndef PASSES
typedef struct {
  int vertexCount;
  int instanceCount;
  int topology;
} ControlBuffer;
#else
typedef struct {
  struct {
    int vertexCount;
    int instanceCount;
    int topology;
  } pass[PASSES];
} ControlBuffer;
#endif

typedef struct {
  float4 iDate;                        // (year, month, day, time in seconds)
  float2 iMouse;                       // mouse pixel coords
  float2 lastTouch;
  float2 iResolution;                  // viewport resolution (in pixels)
  uint2  keyPress;                     // keyPress.x is the current key down
                                       // keyPress.y is the key just clicked on this frame only
  int   iFrame;                       // shader playback frame
  float iTime;                        // shader playback time (in seconds)
  float iTimeDelta;                   // time (in seconds) since last frame
  int wasMouseButtons;
  int eventModifiers;
} Uniform;


struct InputBuffer;

#ifndef SHADOWS
typedef float4 FragmentOutput;
#define LastFrame() constant Uniform &uni [[ buffer(uniformId)]]

#else

#define LastFrame() constant Uniform &uni [[ buffer(uniformId)]], array<texture2d<float>, SHADOWS> lastFrame

typedef struct {
#if SHADOWS > 0
  float4 color0 [[color(0)]];
#endif
#if SHADOWS > 1
  float4 color1 [[color(1)]];
#endif
#if SHADOWS > 2
  float4 color2 [[color(2)]]
#endif
#if SHADOWS > 3
  float4 color3 [[color(3)]]
#endif
#if SHADOWS > 4
  float4 color4 [[color(4)]]
#endif

} FragmentOutput;

#endif


float2 textureSize(texture2d<float> t);

#ifndef shaderName
#warning you must #define shaderName ()
// it would be awesome if I could actually get just the basename of the filename and automate this
#define shaderName __FILE__
#endif

// =========================================================================================

#ifndef ComputeBuffer
#define ComputeBuffer float4
#endif

#define computeFn(a) _computeFn(a, shaderName)
#define _computeFn(a, b) __computeFn(a, b)
#define __computeFn(a, b) kernel void b##___##a##___Kernel ( \
uint3 xCoord [[thread_position_in_grid]], \
constant Uniform &uni [[ buffer(uniformId) ]], \
device InputBuffer &in [[ buffer(kbuffId) ]], \
device ComputeBuffer &computeBuffer [[ buffer(computeBuffId) ]] \
)

// =========================================================================================
// New render

#define vertexFn(...) vertexPass(, ##__VA_ARGS__ )

#define vertexPass(a, ...) _vertexPass(a, shaderName, ##__VA_ARGS__ )
#define _vertexPass(a, b, ...) __vertexPass(a, b, ##__VA_ARGS__ )
#define __vertexPass(a, b, ...) vertex VertexOut b##___##a##___Vertex ( \
uint vid [[ vertex_id ]], \
uint iid [[ instance_id ]], \
constant Uniform &uni [[ buffer(uniformId) ]], \
constant SCNSceneBuffer& scn_frame  [[buffer(0)]], \
constant PerNodeData& scn_node [[buffer(1)]], \
constant InputBuffer &in [[ buffer(kbuffId) ]], \
constant ControlBuffer &ctrl [[buffer(ctrlBuffId) ]], ##__VA_ARGS__ )

// -------

#define fragmentFunc(...) ffFF(shaderName, ##__VA_ARGS__ )
#define ffFF(a, ...) fffFFF(a, ##__VA_ARGS__ )
#define fffFFF(a, ...) fragment float4 a##______Fragment(VertexOut thisVertex [[stage_in]], \
  constant SCNSceneBuffer&    scn_frame   [[buffer(0)]], \
  constant PerNodeData&   scn_node    [[buffer(1)]], ##__VA_ARGS__ \
  )

// #define resolution (scn_node.boundingBox[1].xy)
#define nodeAspect (scn_node.boundingBox[1].xy / scn_node.boundingBox[1].y)
#define worldCoordAdjusted (worldCoord * nodeAspect )


#define fragmentFn(...) fragmentPass(, ##__VA_ARGS__ )

#define fragmentPass(a, ...) _fragmentPass( a, shaderName, ##__VA_ARGS__ )
#define _fragmentPass(a, b, ... ) __fragmentPass(a, b, ##__VA_ARGS__ )
#define __fragmentPass(a, b, ... ) fragment FragmentOutput b##___##a##___Fragment ( \
VertexOut thisVertex [[stage_in]], \
/* constant SCNSceneBuffer& scn_frame  [[buffer(0)]], */ \
/* constant PerNodeData& scn_node [[buffer(1)]], */ \
device InputBuffer &in [[ buffer(kbuffId) ]], \
LastFrame(), \
##__VA_ARGS__)

//array<texture2d<float>, numberOfTextures> texture [[ texture(inputTextureId) ]] )

// =========================================================================================
// New render

#define vertexPointFn(...) _vertexPointFn(shaderName, ##__VA_ARGS__ )
#define _vertexPointFn(b, ...) __vertexPointFn(b, ##__VA_ARGS__ )
#define __vertexPointFn(b, ...) vertex VertexOutPoint b##______Vertex ( \
uint vid [[ vertex_id ]], \
uint iid [[ instance_id ]], \
constant Uniform &uni [[ buffer(uniformId) ]], \
constant InputBuffer &in [[ buffer(kbuffId) ]], \
constant ControlBuffer &ctrl [[buffer(ctrlBuffId) ]], ##__VA_ARGS__ )

// -------

#define fragmentPointFn(...) _fragmentPointFn(shaderName, ##__VA_ARGS__ )
#define _fragmentPointFn(b, ... ) __fragmentPointFn(b, ##__VA_ARGS__ )
#define __fragmentPointFn(b, ... ) fragment float4 b##______Fragment ( \
VertexOutPoint thisVertex [[stage_in]], \
float2 pointCoord [[point_coord]], \
device InputBuffer &in [[ buffer(kbuffId) ]], \
LastFrame(), \
##__VA_ARGS__)
//array<texture2d<float>, numberOfTextures> texture [[ texture(inputTextureId) ]] )

// ===========================================================================================================

// #define worldCoord ((2 * thisVertex.where.xy - uni.iResolution) / uni.iResolution * float2(1, -1))
#define worldCoord ((2 * thisVertex.texCoords - 1) * float2(1, -1))
#define textureCoord ( thisVertex.texCoords )
#define aspectRatio (uni.iResolution / min(uni.iResolution.y, uni.iResolution.x))
#define worldCoordAspectAdjusted (worldCoord * aspectRatio )

// ===========================================================================================================

// this is required for pre-scanning calls to this macro
#define initialize() ___initialize(shaderName)
#define ___initialize(n) __initialize(n)
#define __initialize(n) \
static void _initialize(/* constant Uniform& uni, */ device InputBuffer& in, device ControlBuffer& ctrl ); \
\
kernel void n##_InitializeOptions ( \
/* constant Uniform &uni [[ buffer(uniformId) ]], */ \
  device InputBuffer &in [[ buffer(kbuffId) ]], \
  device ControlBuffer &ctrl [[buffer(ctrlBuffId) ]] \
) { \
  in = InputBuffer(); \
  _initialize( /* uni, */ in, ctrl ); \
} \
\
void _initialize(/* constant Uniform &uni, */ device InputBuffer& in, device ControlBuffer& ctrl )

// ==================================================

// this is required for pre-scanning calls to this macro
#define frameInitialize(...) ___frameInitialize(shaderName, ##__VA_ARGS__)
#define ___frameInitialize(n, ...) __frameInitialize(n, ##__VA_ARGS__)
#define __frameInitialize(n, ...) \
\
kernel void n##_FrameInitialize ( \
  constant Uniform &uni [[ buffer(uniformId) ]], \
  device InputBuffer &in [[ buffer(kbuffId) ]], \
  device ControlBuffer &ctrl [[buffer(ctrlBuffId) ]], ##__VA_ARGS__ )

// =================================================


#define stringSet(a, b) {\
  char unb[] = b; \
  _stringSet(a, sizeof(unb), unb); \
}

// void stringSet(device string& lval, uint n, const char[] );
template <typename T>
static void _stringSet(device string& lval, uint nv, T val) {
  for(unsigned int i = 0;i < nv /*sizeof(val)*/; i++) {
    lval.name[i]=val[i];
  }
}

void stringCopy(device string& lval, uint n, thread char *val);

#endif /* Common_h */
