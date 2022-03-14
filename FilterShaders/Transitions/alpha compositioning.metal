
#define shaderName alpha_compositioning

#include "Common.h" 

struct InputBuffer {
  bool Alpha_compositing;
};

initialize() {
  //  setTex(0, asset::bubbles);
  //  setTex(1, asset::straw);
  in.Alpha_compositing = 1;
}

//optionally skip the main thing, showing a simpler thing without Alpha_compositing

//zoom
#define camLens 1.
//set frame setup
#define frame(u) camLens*(u-.5*uni.iResolution.xy)/uni.iResolution.y

//circle properties
#define radius .3
#define blur .5

//texture properties
#define c0(u)   tex0.sample(iChannel0,u).xyz
#define c1(u)   tex1.sample(iChannel0,u).xyz
//#define cyan    float3(0,1,1)
//#define magenta float3(1,0,1)
//#define yellow  float3(1,1,0)

float4 aOverB(float4 a,float4 b) {
  a.xyz*=a.w;
  b.xyz*=b.w;
  return float4(a+b*(1.-a));
}

//not sure if correct, but looks useful.
float4 aXorB(float4 a,float4 b) {
  a.xyz*=a.w;
  b.xyz*=b.w;
  return float4(a*(1.-b)+b*(1.-a));
}

#define ss(a) smoothstep(blur,-blur,a);
fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 u=frame(thisVertex.where.xy);
  float2 m=frame(uni.iMouse * uni.iResolution);
  float2 n=frame(uni.lastTouch * uni.iResolution);
  if (!uni.mouseButtons) {
    m=.5*float2(cos(uni.iTime*phi),0.);
    n=.5*float2(sin(uni.iTime),cos(uni.iTime));
  }
  float a=length(m-u);a=ss(a-radius);
  float b=length(n-u);b=ss(b-radius);

  if (!in.Alpha_compositing) {
    return float4(a,0,b,1);//2 color channels are set by mouse positions.
  } else {
    float4 a4 = float4(c0(u),a);//colors are set by
    float4 b4=float4(c1(u),b);//alpha channels are set by distance to mouse positions.
    return float4(aXorB(a4, b4).rgb, 1);
  }

}
