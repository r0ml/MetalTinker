
#define shaderName Dot_Line

#include "Common.h"

constant int REPEAT = 32;

frameInitialize() {
//  in.clearColor = {1, 1, 1, 1};
  ctrl.instanceCount = REPEAT;
  ctrl.vertexCount = 1;
  ctrl.topology = 0;
//  in.pipeline._1 = {0, 1, REPEAT, 0};
}

vertexPointFn() {
  VertexOutPoint v;
  
  const float FREQUENCY = 2.5;
  const float AMPLITUDE = 0.08;
  const float RADIUS = 0.9;
  
  
  float phase = float(iid) * TAU / ctrl.instanceCount;
  float offsetValue = sin(uni.iTime * FREQUENCY + phase);
  
  float2 pos = float2( 2 * float(iid) / REPEAT - 1,  2 * AMPLITUDE * offsetValue);
  float radius = (offsetValue + 1.1) * RADIUS;
  radius *= uni.iResolution.y / (1.1 * REPEAT);
  
  v.point_size = radius;
  v.color = {0, 0, 0, 1};
  v.where.xy = pos;
  v.where.zw = {0, 1};
  return v;
}

fragmentPointFn() {
  const float BLUR = 0.1;
  float c = smoothstep(0.5-BLUR, 0.5, length(pointCoord-0.5));
  return float4(c, c, c, 1);
}
