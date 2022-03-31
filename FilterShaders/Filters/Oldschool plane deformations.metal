
#define shaderName oldschool_plane_deformation

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 uv=worldCoordAspectAdjusted;
  uv.y=abs(uv.y);
  return tex.sample(iChannel0,fract(float2((uv.x/uv.y)+(sin(uni.iTime * M_PI_F * 0.25)*2.0),
                                                  (1.0/uv.y)+(cos(uni.iTime * M_PI_F * 0.3)*2.0))))*uv.y;
}
