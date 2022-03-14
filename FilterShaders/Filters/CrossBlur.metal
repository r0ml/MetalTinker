
#define shaderName CrossBlur

#include "Common.h" 
struct InputBuffer {
    bool GLARE_BLOOM = false;
};

initialize() {
}

static float3 getBloom(float2 coord, float2 reso, texture2d<float> tex){
  
  const int samples = 32;
  float3 color = 0;
  //    float colorTresh;
  int weight = 0;
  
  float size = 12.0; //size in pixels
  
  for (int i = 0; i < samples;i++){
    
    float2 coord0 = coord + (float2(i,i) * size / float(samples)   / reso);
    float2 coord1 = coord + (float2(-i,-i) * size / float(samples) / reso);
    float2 coord2 = coord + (float2(-i,i) * size / float(samples)  / reso);
    float2 coord3 = coord + (float2(i,-i) * size / float(samples)  / reso);
    
    color += tex.sample(iChannel0, coord0).rgb;
    color += tex.sample(iChannel0, coord1).rgb;
    color += tex.sample(iChannel0, coord2).rgb;
    color += tex.sample(iChannel0, coord3).rgb;
    
    weight++;
  }
  
  color /= float(weight);
  color = pow(color,float3(1.0));
  
  return (color / 4.0);
}

fragmentFn(texture2d<float> tex) {
  float2 b = textureCoord;
  float3 getColor = in.GLARE_BLOOM ? mix(tex.sample(iChannel0, b).rgb, getBloom(b, uni.iResolution, tex) * 2.0,0.5) : getBloom(b, uni.iResolution, tex);
  
  return float4(getColor,1.0);
}
