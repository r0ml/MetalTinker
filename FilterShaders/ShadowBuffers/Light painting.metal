
#define shaderName light_painting

#include "Common.h" 

fragmentFn( texture2d<float> webcam, texture2d<float> lastFrame ) {
  float2 uv = thisVertex.where.xy / uni.iResolution;
  float4 col = lastFrame.sample(iChannel0, uv);
  col = pow(col, float4(3));
  float4 fragColor = col*0.005 + webcam.sample(iChannel0, uv);

  if ( uni.wasMouseButtons ) {
    fragColor = 0;
  }
  return fragColor;
}
