
#define shaderName more_spirograph

#include "Common.h"

#define STEPS 50
#define ITERS 9

static float Config(float t){
  float sgn=1.0;
  if(mod(t,54.0)>27.0)sgn=-1.0;
  t=floor(mod(t,27.0));
  if(t<10.0)
    return (2.0+t*0.25)*sgn;
  t-=10.0;
  if(t<10.0)return (2.0+t*0.33333)*sgn;
  t-=10.0;
  if(t<1.0)return 3.82845*sgn; //I have no idea what this pattern is (similar to note freq)
  if(t<2.0)return 3.64575*sgn; //these give the regular polygons
  if(t<3.0)return 3.44955*sgn;
  if(t<4.0)return 2.7913*sgn;
  if(t<5.0)return 2.5616*sgn;
  if(t<6.0)return 2.4495*sgn;
  return 2.30275*sgn;
}

static float2 F(float t, float scale){
  float a=t,r=1.0;
  float2 q=float2(0.0);
  for(int j=0;j<ITERS;j++){
    q+=float2(cos(a),sin(a))*r;
    a*=scale;r/=abs(scale);
  }
  return q;
}

static float2 DF(float2 p, float t, float scale){
  float d1=length(p-F(t, scale)),dt=0.1*d1,d2=length(p-F(t+dt, scale));
  dt/=max(dt,d1-d2);
  return float2(min(d1,d2),0.4*log(d1*dt+1.0));
}

fragmentFn( texture2d<float> lastFrame ) {
  float scale;

  float3 col=lastFrame.sample(iChannel0,thisVertex.where.xy/uni.iResolution.xy).rgb;
  float2 p=(2.0*thisVertex.where.xy-uni.iResolution.xy)/uni.iResolution.y;
  p*=1.75;
  
  float tim=(uni.iTime+99.0)*0.2;
  scale=Config(tim);//mix(Config(tim),Config(tim+1.0),smoothstep(0.5,1.0,fract(tim)));
  float t=uni.iTime*100.0,d=100.0;
  for(int i=0;i<STEPS;i++){
    float2 v=DF(p,t, scale);
    d=min(d,v.x);
    t+=v.y;
  }
  d=smoothstep(0.0,0.01,d);
  col=mix(min(col,float3(d*d*d,d*d,d)),float3(1.0),0.01);
  return float4(col,1.0);
}
