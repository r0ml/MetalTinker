
#define shaderName image_cel_shade

#include "Common.h" 
 
float3 lerp(float3 colorone, float3 colortwo, float value) {
  return (colorone + value*(colortwo-colorone));
}

fragmentFn(texture2d<float> tex) {
  float nColors = 4.0;
  float vx_offset = 0.5;
  float2 uv = textureCoord;
  float3 tc = tex.sample(iChannel0, uv).rgb;
  // float2 coord = float2(0.,0.);
  
  float cutColor = 1./nColors;
  
  if(uv.x < (vx_offset-0.001))
  {
    
    tc = rgb2hsv(tc);
    
    float2 target_c = cutColor*floor(tc.gb/cutColor);
    
    tc = hsv2rgb(float3(tc.r,target_c));
  }
  else if (uv.x>=(vx_offset+0.01))
  {
    
    tc  = cutColor*floor(tc/cutColor);
  }
  
  
  
  if(tc.g > (tc.r + tc.b)*0.7)
  {
    //tc.rgb = float3(0.2,0.2,0.2);
  }
  
  
  return float4(tc, 1.0);
  
}


