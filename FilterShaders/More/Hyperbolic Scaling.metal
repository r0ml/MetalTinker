
#define shaderName Hyperbolic_Scaling

#include "Common.h"
struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  // Set up a coordinate system with the origin at the bottom-center.
  float2 uv=textureCoord * aspectRatio - float2(0.5, 0);

  float k=2.0;                // Scaling exponent for each layer
  float t=mod(uni.iTime/3.0,1.0); // Repeats every three seconds; 0 <= t < 1
  
  float3 col=float3(0.0);
  float tot=0.0;
  for(int i=-9;i<=9;i++){
    // Compute scaling of the ith layer
    float py=pow(k,t+float(i));
    float px=pow(k,t+float(i));
    // Sampling positions
    float nx=uv.x/px;
    float ny=uv.y*py;
    // Compute blend of the ith layer
    float sc=pow(2.0,-abs(float(i)+t));
    col+=sc*tex.sample(iChannel0,float2(nx,ny)).rgb;
    tot+=sc;
  }
  
  col=col/tot;
  
  return float4(col, 1.0);
}
