
#define shaderName feedback_circles

#include "Common.h" 

static float3 subImg( const float2 winCoord, float xs,float ys, float zs, float time, float2 reso, texture2d<float> rendin0){
  sampler chan(coord::normalized, address::clamp_to_edge, filter::linear);
  float2 xy=winCoord/reso;
  xy-=0.5;
  xy+=float2(sin(time*xs)*0.1,cos(time*ys)*0.1);//move
  xy*=(1.1+sin(time*zs)*0.1);//scale
  xy+=0.5;
  return rendin0.sample(chan,xy).xyz;
}

static float3 drawCircle(const float2 xy){
  float l=length(xy);
  return ( l>.233 || l<.184 ) ? float3(0) : float3(sin(l*128.0)*.5+0.5);
}

fragmentFn( texture2d<float> lastFrame ) {

  //circle zoom and deformation
  float2 xy=uni.iResolution.xy;xy=-.5*(xy-2.0*thisVertex.where.xy)/xy.x;
  xy*=1.0+sin(uni.iTime*4.0)*0.2;
  xy.x+=sin(xy.x*32.0+uni.iTime*16.0)*0.01;
  xy.y+=sin(xy.y*16.0+uni.iTime*8.0)*0.01;

  float3 c=drawCircle(xy);

  float3 fC=
  subImg(thisVertex.where.xy,3.3,3.1,2.5, uni.iTime, uni.iResolution, lastFrame)*float3(0.3,0.7,1.0)+
  subImg(thisVertex.where.xy,2.4,4.3,3.3, uni.iTime, uni.iResolution, lastFrame)*float3(0.3,1.0,0.7)+
  subImg(thisVertex.where.xy,2.2,4.2,4.2, uni.iTime, uni.iResolution, lastFrame)*float3(1.0,0.7,0.3)+
  subImg(thisVertex.where.xy,3.2,3.2,2.1, uni.iTime, uni.iResolution, lastFrame)*float3(1.0,0.3,0.7)+
  subImg(thisVertex.where.xy,2.2,1.2,3.4, uni.iTime, uni.iResolution, lastFrame)*float3(0.3,0.5,0.7)+
  subImg(thisVertex.where.xy,5.2,2.2,2.2, uni.iTime, uni.iResolution, lastFrame)*float3(0.8,0.5,0.1);

  return float4( (fC/3.6+c)*0.95 ,1.0);
}
