
#define shaderName Radar_2

#include "Common.h"

static float mark(int n,float ang2,float2 uv,float mn,float mx, float2 reso) {
  float aa=1/reso.y;
  ang2-=tau/float(n)/2.;
  return smoothstep(mn,mx,distance(uv,float2(0)))*smoothstep(aa*2.,0.,abs(fract(ang2/tau*float(n))-0.5)/float(n)*tau*distance(uv,float2(0)));
}

static float circle(float dist,float2 uv, float2 reso){
  float aa=1/reso.y;
  return (smoothstep(dist-aa*2.,dist-aa,distance(uv,float2(0)))-smoothstep(dist,dist+aa,distance(uv,float2(0))))/10.;
}

static float point(float2 coord,float2 uv,float ang, float2 reso){
  float aa=1/reso.y;
  return smoothstep(0.004+aa,0.002,distance(uv,coord))*smoothstep(tau*0.7,0.,ang)/2.;
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  float aa=1/uni.iResolution.y;
  
  //uv.x+=(rand(uv*uni.iTime)-0.5)/100.*smoothstep(0.7,1.,hash(floor(uni.iTime)));
  
  float dist=distance(uv,float2(0));
  float sdist=smoothstep(0.5+aa,0.5,dist);
  
  float ang=uni.iTime*tau/5.;
  float ang2=atan2(uv.x,uv.y);
  ang=mod(ang2+ang,tau);
  
  float col=smoothstep(1.,0.,ang);
  col/=2.;
  col+=smoothstep(tau-aa/distance(uv,float2(0)),tau,ang)/2.;
  col+=sdist/10.;
  col+=smoothstep(aa,0.,abs(uv.x))/4.;
  col+=smoothstep(aa,0.,abs(uv.y))/4.;
  
  col+=mark(9*4,ang2,uv,0.45,0.5, uni.iResolution)/2.;
  col+=mark(9*4*5,ang2,uv,0.475,0.5, uni.iResolution)/5.;
  col+=circle(0.1,uv, uni.iResolution);
  col+=circle(0.2,uv, uni.iResolution);
  col+=circle(0.3,uv, uni.iResolution);
  col+=circle(0.4,uv, uni.iResolution);
  col+=point(float2(0.3,0.1),uv,ang, uni.iResolution);
  col+=point(float2(-0.2,-0.3),uv,ang, uni.iResolution);
  col+=point(float2(0.2,-0.1),uv,ang, uni.iResolution);
  
  float4 fragColor = mix(float4(0,col,0,0),float4(0.055,0.089,0.0,0)/1.3,1.-sdist);
  
  float l=cos(thisVertex.where.y);
  l*=l;
  l/=3.;
  l+=0.6+rand(uv*uni.iTime);
  
  fragColor*=l;
  fragColor.w = 1;
  return fragColor;
}
