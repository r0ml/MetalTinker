
#define shaderName Arcs

#include "Common.h"

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



vertexPass(_1) {
  VertexOut v;

  v.where.xy = annulus(vid, arcSides, in.radius.y - in.thickness.y / 2, in.radius.y + in.thickness.y / 2,
                     iid * PI/4, (iid + 1) * PI/4);

//  a.xy = (a.xy * aspect * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.))) / aspect;

  v.where.zw = {0, 1};
  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  v.color = {0.5 + 0.2 * (iid == 1), 0.5, 0.5 + 0.2 * (iid == 2), 1};
  return v;
}

/*
vertexPass(_2) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.y;
  v.where.xy = annulus(vid, arcSides, in.radius.y - in.thickness.y / 2, in.radius.y + in.thickness.y / 2,
                     aspect, PI/4, PI/2 );

//  a.xy = (a.xy * aspect * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.))) / aspect;

  v.where.zw = {0, 1};
  v.color = {0.7, 0.5, 0.5, 1 };
  return v;
}

vertexPass(_3) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.y;
  v.where.xy = annulus(vid, arcSides, in.radius.y - in.thickness.y / 2, in.radius.y + in.thickness.y / 2,
                     aspect, PI/2, 3 * PI/4 );

//  a.xy = (a.xy * aspect * rot2d( -uni.iTime * 5. + (sin(uni.iTime) * 3. + 1.))) / aspect;

  v.where.zw = {0, 1};
  v.color = {0.5, 0.5, 0.7, 1 };
  return v;
}
*/
