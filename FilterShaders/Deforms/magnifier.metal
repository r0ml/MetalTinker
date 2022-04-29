
#define shaderName magnifier

#include "Common.h" 

constant const float radius=2.;
constant const float depth=radius/2.;

fragmentFn( texture2d<float> tex) {
  float2 uv = textureCoord;
  float2 center = uni.iMouse.xy;
  float2 uc = uv - center;
//  float2 ucx = uc / float2(0.2*0.2, )
  float ax = (uc.x * uc.x) / (0.2*0.2) + ((uc.y * uc.y) / (0.2/ (  uni.iResolution.x / uni.iResolution.y ))) ;
  float dx = (-depth/radius)*ax + (depth/(radius*radius))*ax*ax;
  float f =  (ax + dx );
  if (ax > radius) f = ax;
  float2 magnifierArea = center + (uv-center)*f/ax;
  return float4(tex.sample( iChannel0, magnifierArea ).rgb, 1.);
}