
#define shaderName triskel2

#include "Common.h"
/*
 #include <metal_stdlib>
 using namespace metal;
 #include <SceneKit/scn_metal>
 */


/*
 fragmentFn() {

 return float4(0.3, 0.4, 0.6, 1);

 }
 */


/*
 // ------
 float2 U = worldCoordAspectAdjusted + float2(0,.1);

 float a = -floor((atan2(U.y,U.x)-.33)*3./tau)/3.*tau -.05, l; // 3 symmetries
 U *= float2x2(cos(a),-sin(a),sin(a),cos(a));
 U = 3.*(U-float2(0,.577));

 l = length(U), a = atan2(U.y,U.x);                        // spiral
 float4 fragColor = float4( l + fract((a+2.25)/tau) < 2. ? .5+.5*sin(a+tau*l) : 0.);

 return smoothstep(.0,.1,abs(fragColor-.5)) - smoothstep(.8,.9,fragColor);   // optional decoration

 */

fragment float4 triskel2______Fragment(VertexOut thisVertex [[stage_in]],
                                       constant SCNSceneBuffer&    scn_frame   [[buffer(0)]],
                                       constant PerNodeData&   scn_node    [[buffer(1)]]
                                       ) {

  float2 z = worldCoord;
  float2 h = scn_node.boundingBox[1].xy; //  scn_node.boundingBox[0].xy
  float2 asrat = h.xy/h.y;

  float2 U = z * asrat + float2(0,.1);

  float a = -floor((atan2(U.y,U.x)-.33)*3./tau)/3.*tau -.05, l; // 3 symmetries
  U *= float2x2(cos(a),-sin(a),sin(a),cos(a));
  U = 3.*(U-float2(0,.577));

  l = length(U), a = atan2(U.y,U.x);                        // spiral
  float4 fragColor = float4( l + fract((a+2.25)/tau) < 2. ? .5+.5*sin(a+tau*l) : 0.);

  return smoothstep(.0,.1,abs(fragColor-.5)) - smoothstep(.8,.9,fragColor);   // optional decoration

}
