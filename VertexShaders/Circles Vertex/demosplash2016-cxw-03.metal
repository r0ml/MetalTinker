
#define shaderName demosplash2016_cxw_03

#include "Common.h"

static float4 do_color(const float time, const float2 coords)
{
  float whereami =
  50.0*distance(float2(0.5),coords) - 10.0*time;
  //  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   ^^^^^^^^^
  //          frequency terms           phase terms
  //
  //  ^^^^ how many rings (50/2pi)      ^^^^ how fast they move (2pi/peak)
  //
  //       ^^^^^^^^^^^^^^^^^^^^^^^^^^ radial pattern
  return float4(0.0,0.0,
                0.5+0.5*sin(whereami),  // render in the blue channel
                1.0);
} //do_color

fragmentFn() {
  float t = uni.iTime;
  float2 uv = textureCoord;
  float4 scene_color = do_color(t, uv);
  float window =  1.0;

  return scene_color * window;
}
