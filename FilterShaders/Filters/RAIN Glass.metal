
#define shaderName rain_glass

#include "Common.h" 

fragmentFunc(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord;
  float2 uv1= float2(uv.y*0.1-scn_frame.time*0.095,uv.x*2.);
  float3 rain=tex0.sample(iChannel0,uv1).rgb/8.;
  float2 uv2 = uv.xy-rain.xy;
  return tex1.sample(iChannel0,uv2+0.04);
}
