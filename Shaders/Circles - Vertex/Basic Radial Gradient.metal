
#define shaderName basic_radial_gradiant

#include "Common.h" 

struct InputBuffer {
  struct {
    int4 _1;
  } pipeline;
  struct {
    int a;
    int b;
  } variant;
};
initialize() {
  in.pipeline._1 = { 3, 150, 1, 0 };
  in.variant.a = 1;
}


vertexPass(_1) {
  float radius = (sin(uni.iTime) + 1.5) / 4.7;

  VertexOut v;
  v.where.xy = polygon(vid, in.pipeline._1.y / 3, radius);
  v.where.zw = {0, 1};
  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  if (mod(vid,3) == 0) {
    if (in.variant.a) {
      v.color = 1;
    } else if (in.variant.b) {
      v.color = { 1.7,1.4,1.2,1 };
    }
  } else {
    if (in.variant.a) {
      v.color = float4(1, 1, 1, 0);
    } else if (in.variant.b) {
      v.color = { 0.7, 0.4, 0.2, 0 };
    }
  }

  return v;
}

/*
fragmentFn() {
  float2 f = worldCoordAspectAdjusted;
  float d = distance(0,f)*(sin(uni.iTime) + 1.5) * 2.2;
	return mix(float4(1.0, 1.0, 1.0, 1.0), float4(0.0, 0.0, 0.0, 1.0), d);
}

*/
