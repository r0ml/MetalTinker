
#define shaderName isovalues_video

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}


static float4 T(float2 uv, float i, float j, float2 reso, texture2d<float>vid) {
  return vid.sample(iChannel0, uv/reso + float2(i,j)/textureSize(vid));
}

fragmentFn(texture2d<float> tex) {
  float4 fragColor = (
                      T(thisVertex.where.xy, -1,-1, uni.iResolution, tex)+
                      T(thisVertex.where.xy, 0,-1 , uni.iResolution, tex)+
                      T(thisVertex.where.xy, 1,-1,  uni.iResolution, tex)+
                      T(thisVertex.where.xy, -1, 0, uni.iResolution, tex)+
                      T(thisVertex.where.xy, 0, 0,  uni.iResolution, tex)+
                      T(thisVertex.where.xy, 1, 0,  uni.iResolution, tex)+
                      T(thisVertex.where.xy, -1, 1, uni.iResolution, tex)+
                      T(thisVertex.where.xy, 0, 1,  uni.iResolution, tex)+
                      T(thisVertex.where.xy, 1, 1,  uni.iResolution, tex) ) / 9.;

  float v = sin(TAU*3.*length(fragColor.xyz));

  fragColor *= 1.-smoothstep(0.,1., .5*abs(v)/fwidth(v));
  fragColor.w = 1;
  return fragColor;
}
