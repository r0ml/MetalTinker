
#define shaderName Spinning_Star

#include "Common.h"

struct KBuffer {
  float4 clearColor;
  struct {
    bool polar;
    float3 size;
  } options;
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  kbuff.pipeline._1 = { 3, 3, 3, 0 } ; // 3 (overlapping) triangles -- that last value is bits:  the low order bit means not 3-d (blend)
  kbuff.options.polar = false;
  kbuff.options.size = {0.6, 0.5, 1.0};
  kbuff.clearColor = gammaDecode(float4(0.15, 0.45, 0.35, 1));
}

vertexFn(_1) {
  VertexOut v;
  float2 aspect = uni.iResolution / uni.iResolution.x;

  float x = kbuff.options.size.y * cos(radians(18.));
  float y = x * tan(radians(36.));
  float z = y - x * sin(radians(18.));

  float2 p = float2(0, mix(z, kbuff.options.size.y, (vid % 2) == 0));
  float angle = TAU * vid * 3 / 10.;

  angle += uni.iTime * 0.2;
  p = (p * aspect) * rot2d( angle + TAU * iid / 5.);

  p = p / aspect;

//  v.barrio.xy = p;
//  v.barrio.zw = 0;

  v.where.xy = p;   // (2 * v.barrio.xy - 1) * 0.5 ;
  v.where.zw = {0, 1};

  v.color =  gammaDecode(float4(0.65, 0.85, 0.45, 1.0));
  return v;
}
