
#define shaderName circles_3_animation

#include "Common.h"

constant const int vc = 150;

frameInitialize() {
  ctrl.topology = 2;
  ctrl.vertexCount = vc;
  ctrl.instanceCount = 3;
}

vertexFn() {
  VertexOut v;
  int ix = (int)iid - 1;
  float radius = 0.15 + sin(uni.iTime) * 0.05 * (iid == 1);
  v.where.xy = polygon(vid, ctrl.vertexCount / 3, radius); 
  v.where.xy += float2(0.2 * ix, 0);
  v.where.xy -= sin(uni.iTime) * 0.1 * ix;
  v.where.zw = {0, 1};
  v.color =
  float4(0.301, 0.670, 0.960,1.0) * (iid == 0) +
  float4(0.129, 0.588, 0.952,1.0) * (iid == 1) +
  float4(0.090, 0.411, 0.666,1.0) * (iid == 2);

  v.where = v.where * scale( aspectRatio.y, aspectRatio.x, 1);
  return v;
}

/*
fragmentFn() {
  float2 circlePos1 = float2(0.3,0.5);
  float2 circlePos2 = float2(0.5,0.5);
  float2 circlePos3 = float2(0.7,0.5);
  float radius1 = 0.15;
  float radius2 = 0.15;
  float radius3 = 0.15;
  float4 FG1 = float4(0.301, 0.670, 0.960,1.0);
  float4 FG2 = float4(0.129, 0.588, 0.952,1.0);
  float4 FG3 = float4(0.090, 0.411, 0.666,1.0);
  float4 BG = float4(1.0,1.0,1.0,1.0);
  
  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  float aspectRatiox = uni.iResolution.y / uni.iResolution.x;
  uv.y = uv.y * aspectRatiox;
  
  circlePos1.y = circlePos1.y * aspectRatiox;
  circlePos2.y = circlePos2.y * aspectRatiox;
  circlePos3.y = circlePos3.y * aspectRatiox;
  
  circlePos1 += sin(uni.iTime) * 0.1;
  radius2 += sin(uni.iTime) * 0.05;
  circlePos3 -= sin(uni.iTime) * 0.1;
  
  float4 fragColor = mix(FG3, BG, smoothstep(radius3 - 2e-3, radius3, length(circlePos3 - uv)));
  fragColor = mix(FG2, fragColor, smoothstep(radius2 - 2e-3, radius2, length(circlePos2 - uv)));
  fragColor = mix(FG1, fragColor, smoothstep(radius1 - 2e-3, radius1, length(circlePos1 - uv)));
  return fragColor;
}
*/
