
#define shaderName Spinning_circles

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
  float phase = -(uni.iTime / 2.0) * TAU;
  float radius = 0.05 + (cos(phase) * 0.005);

  v.color = {0, 0, 0, 1};
  v.color[iid]=1;

  v.where.xy = polygon(vid, ctrl.vertexCount / 3, radius);
//  v.where.xy -= sin(uni.iTime) * 0.1 * ix;
  v.where.zw = {0, 1};

  float2 off = /*float2(0.2 * ix, 0) + */ ( float2(cos(phase), sin(phase)) * 0.15) * ix /* - sin(uni.iTime) * 0.1 * ix */ +  toWorld(uni.iMouse) * aspectRatio ; // * (uni.mouseButtons != 0) ;
//  off /= aspectRatio;
  v.where =   scale(1 / aspectRatio.x, 1 / aspectRatio.y, 1)  * translation( off.x, off.y, 0) * v.where ;

  return v;
}

/*
static float circle (float2 center, float2 winCoord, float radius, float pixelWidth) {
  return smoothstep(radius + pixelWidth, radius - pixelWidth, length(winCoord - center));
}

fragmentFn() {
  float pixelWidth = 1.0 / min(uni.iResolution.x, uni.iResolution.y);
  float2 pos = worldCoordAspectAdjusted / 2;
  float2 mouse = (uni.iMouse.xy - 0.5) * aspectRatio;
  
  float phase = -(uni.iTime / 2.0) * TAU;
  float radius = 0.05 + (cos(phase) * 0.01);
  float4 fragColor = 0;
  fragColor.r += circle(float2(cos(phase), sin(phase)) *  0.15 + mouse, pos, radius, pixelWidth);
  fragColor.g += circle(float2(0.0) + mouse, pos, radius, pixelWidth);
  fragColor.b += circle(float2(cos(phase), sin(phase)) * -0.15 + mouse, pos, radius, pixelWidth);
  fragColor.w = 1;
  return fragColor;
}
*/
