
#define shaderName isovalues_video

#include "Common.h" 

static float4 T(float2 uv, float i, float j, texture2d<float>vid) {
  return vid.sample(iChannel0, uv + float2(i,j)/textureSize(vid));
}

fragmentFunc(texture2d<float> tex) {
  float2 tc = textureCoord;
  float4 fragColor = (
                      T(tc, -1,-1, tex)+
                      T(tc, 0,-1 , tex)+
                      T(tc, 1,-1,  tex)+
                      T(tc, -1, 0, tex)+
                      T(tc, 0, 0,  tex)+
                      T(tc, 1, 0,  tex)+
                      T(tc, -1, 1, tex)+
                      T(tc, 0, 1,  tex)+
                      T(tc, 1, 1,  tex) ) / 9.;

  float v = sin(TAU*3.*length(fragColor.xyz));

  fragColor *= 1.-smoothstep(0.,1., .5*abs(v)/fwidth(v));
  fragColor.w = 1;
  return fragColor;
}
