
#define shaderName pastelstorm

#include "Common.h" 

constant const float2x2 m = float2x2( 0.80,  0.60, -0.60,  0.80 );

static float noise( float2 x ) {
  return sin(1.5*x.x)*sin(1.5*x.y);
}

static float fbm6( float2 p ) {
  float f = 0.0;
  f += 0.500000*(0.5+0.5*noise( p )); p = m*p*2.02;
  f += 0.250000*(0.5+0.5*noise( p )); p = m*p*2.03;
  f += 0.125000*(0.5+0.5*noise( p )); p = m*p*2.01;
  f += 0.062500*(0.5+0.5*noise( p )); p = m*p*2.04;
  f += 0.031250*(0.5+0.5*noise( p )); p = m*p*2.01;
  f += 0.015625*(0.5+0.5*noise( p ));
  return f/0.96875;
}

static float pattern( float2 p, float time ) {
  float2 q = float2( fbm6( p + float2(0.0,0.0) ),          fbm6( p + float2(5.2,1.3) ) );
  float2 r = float2( fbm6( p + 4.0*q + float2(-1.2,9.2) ), fbm6( p + 4.0*q + float2(8.3,2.8) ) );
  return fbm6( p + 4.0*r + sin(time/3.));
}

fragmentFn( texture2d<float> lastFrame ) {
  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  if(uni.iFrame<1){
    return float4(uv.xy, fbm6(uv), fbm6(uv.yx));
  } else {
    float4 last = lastFrame.sample(iChannel0, uv);
    float4 fragColor = float4(
                              pattern(uv + mod(last.z, 8.)*float2(sin(uni.iTime/2.), cos(uni.iTime/8.)), uni.iTime),
                              pattern(uv + mod(last.y, 7.)*float2(sin(uni.iTime/3.), cos(uni.iTime/7.)), uni.iTime),
                              pattern(uv + mod(last.x, 4.)*float2(sin(uni.iTime/5.), cos(uni.iTime)), uni.iTime),
                              1);
    return mix(fragColor, last, sin(fragColor.x + fragColor.y + fragColor.z));
  }
}
