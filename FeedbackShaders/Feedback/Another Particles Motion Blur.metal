
#define shaderName Another_Particles_Motion_Blur

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {
//  float halfpi = atan(-1.0)*-2.0;
  float halfpi = PI / 2;
  float2 g = thisVertex.where.xy;
  float4 h = lastFrame.read(uint2(thisVertex.where.xy));
  g = (g * 2.-uni.iResolution)/uni.iResolution.y*2.5;
  float prec = 0.005;
  float color = 0.0;
  for (int i = -7; i < 8; ++i) {
    float2 k = float2(halfpi + float(i) * 0.1,0) + mod(uni.iTime * 0.1 * (float(i) + 0.4) * 0.2, 4.0 * halfpi);
    float2 a = mod(g - sin(k + k * log(k)*0.9),g)-g*.5;
    float2 b = mod(g - sin(2.09 + k * sin(k)*0.8),g)-g*.5;
    float2 c = mod(g - sin(4.18 + k * cos(k)*0.7),g)-g*.5;
    color += (prec/dot(a,a) + prec/dot(b,b) + prec/dot(c,c));
  }
  return color * 0.001 + h * 0.97 + step(h, float4(.8,.2,.5,1)) * 0.01;
}
