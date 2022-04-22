
#define shaderName boreal_plasma

#include "Common.h" 
struct InputBuffer {
  struct {
    int _1;
    int _2;
  } variant;
};

initialize() {
  in.variant._1 = 1;
}

fragmentFn(texture2d<float> tex, texture2d<float> lastFrame) {

  constexpr sampler chan(coord::normalized, address::clamp_to_edge, filter::linear);
  // prev image is dezoomed and offseted
  // new image blended on top is color-shifted and threaded by the high pow.
  
  float2 U = thisVertex.where.xy/uni.iResolution.xy-.5;
  float t = uni.iTime;
  float3 rpi = lastFrame.sample(chan, U*1.015+.5 - 0.006*sin(0.3*t+float2(0,1.6))).rgb;
  
  float3 vv = 1;
  
  if (in.variant._1) {
    float3 noi = interporand( thisVertex.where.xy / uni.iResolution ) ;
    vv = pow(.5+.5*sin(6.3*noi + t+float3(0,2.1,-2.1)), 20.0);
  } else if (in.variant._2) {
    float3 noi = tex.sample(iChannel0, U).rgb;
    vv = pow(abs(sin(6.3 * noi + t)), 40.0);
  }
  
  float3 res = saturate(mix( rpi, vv, 0.03));
  
  //pow(abs(sin(6.3*texture(iChannel1, U)+ t+float4(0,2.1,-2.1,0))),float4(20)),     // variant
  //.5+.5*sin(6.3*pow(texture(iChannel1, U),float4(6))+ 10.*t+float4(0,2.1,-2.1,0)), // variant
  
  //pow(.5+.5*sin(6.3*(U.y+texture(iChannel1, U))+ t),float4(40)),  // variant
  //.5+.5*sin(6.3*pow(texture(iChannel1, U),float4(6))+ 10.*t),     // variant
  
  return float4(res, 1);
}
