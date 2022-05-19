
#define shaderName oldschool_plane_deformation

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  float2 uv=worldCoordAdjusted;
  uv.y=abs(uv.y);
  float t = scn_frame.time;
  return tex.sample(iChannel0,fract(float2((uv.x/uv.y)+(sin(t * M_PI_F * 0.25)*2.0),
                                                  (1.0/uv.y)+(cos(t * M_PI_F * 0.3)*2.0))))*uv.y;
}
