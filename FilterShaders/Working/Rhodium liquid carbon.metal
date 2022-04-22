/** 
 Author: Virgill
 Liquid carbon effect from Rhodium 4k Intro
 4kb executable: http://www.pouet.net/prod.php?which=68239
 https://www.youtube.com/watch?v=YK7fbtQw3ZU
 */
#define shaderName Rhodium_liquid_carbon_2

#include "Common.h"

struct KBuffer {
  //  string music[1];
};

initialize() {
  // setMusic(0, asset::sonika);
}






// ***********************************************************
// Alcatraz / Rhodium 4k Intro liquid carbon
// by Jochen "Virgill" Feldkötter
//
// 4kb executable: http://www.pouet.net/prod.php?which=68239
// Youtube: https://www.youtube.com/watch?v=YK7fbtQw3ZU
// ***********************************************************

// 	simplyfied version of Dave Hoskins blur
static float3 dof(texture2d<float> tex,float2 uv,float rad, float2 reso)
{
  const float GA =2.399;
  const float2x2 rot = rot2d(GA);
  float3 acc=float3(0);
  float2 pixel=float2(.002*reso.y/reso.x,.002),angle=float2(0,rad);;
  rad=1.;
  for (int j=0;j<80;j++)
  {
    rad += 1./rad;
    angle*=rot;
    float4 col=tex.sample(iChannel0,uv+pixel*(rad-1.)*angle);
    acc+=col.xyz;
  }
  return acc/80.;
}


static float map(float3 p, float bounce, float time)
{
  p.z-=1.0;
  p*=0.9;
  p.yz = p.yz * rot2d(bounce*1.+0.4*p.x);
  return sdBox(p+float3(0,sin(1.6*time),0),float3(20.0, 0.05, 1.2))-.4*noisePerlin(8.*p+3.*bounce);
}

//  normal calculation
static float3 calcNormal(float3 pos, float bounce, float time)
{
  float eps=0.0001;
  float d=map(pos, bounce, time);
  return normalize(float3(map(pos+float3(eps,0,0), bounce, time)-d,map(pos+float3(0,eps,0), bounce, time)-d,map(pos+float3(0,0,eps), bounce, time)-d));
}


//   standard sphere tracing inside and outside
static float castRayx(float3 ro,float3 rd, float bounce, float time)
{
  float function_sign=(map(ro, bounce, time)<0.)?-1.:1.;
  float precis=.0001;
  float h=precis*2.;
  float t=0.;
  for(int i=0;i<120;i++)
  {
    if(abs(h)<precis||t>12.)break;
    h=function_sign*map(ro+rd*t, bounce, time);
    t+=h;
  }
  return t;
}

//   refraction
static float refr(float3 pos,float3 lig,float3 dir,float3 nor,float angle,thread float& t2, thread float3& nor2, float bounce, float time)
{
  float h=0.;
  t2=2.;
  float3 dir2=refract(dir,nor,angle);
  for(int i=0;i<50;i++)
  {
    if(abs(h)>3.) break;
    h=map(pos+dir2*t2, bounce, time);
    t2-=h;
  }
  nor2=calcNormal(pos+dir2*t2, bounce, time);
  return(.5*saturate(dot(-lig,nor2))+pow(max(dot(reflect(dir2,nor2),lig),0.),8.));
}

//  softshadow
static float softshadow(float3 ro,float3 rd, float bounce, float time)
{
  float sh=1.;
  float t=.02;
  float h=.0;
  for(int i=0;i<22;i++)
  {
    if(t>20.)continue;
    h=map(ro+rd*t, bounce, time);
    sh=min(sh,4.*h/t);
    t+=h;
  }
  return sh;
}

//-------------------------------------------------------------------------------------------
fragmentFn1()
{
  FragmentOutput fff;
  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  fff.fragColor=float4(dof(renderInput[0],uv,renderInput[0].sample(iChannel0,uv).w, uni.iResolution),1.);


  // ============================================== buffers =============================

float bounce;


  bounce=abs(fract(0.05*uni.iTime)-.5)*20.; // triangle function
  
  //	float2 uv=thisVertex.where.xy/res.xy;
  // float2 p=uv*2.-1.;
  
  // 	bouncy cam every 10 seconds
  float wobble=(fract(.1*(uni.iTime-1.))>=0.9)?fract(-uni.iTime)*0.1*sin(30.*uni.iTime):0.;
  
  //  camera
  float3 dir = normalize(float3(2.*thisVertex.where.xy -uni.iResolution.xy, uni.iResolution.y));
  float3 org = float3(0,2.*wobble,-3.);
  
  
  // 	standard sphere tracing:
  float3 color = float3(0.);
  float3 color2 =float3(0.);
  float t=castRayx(org,dir, bounce, uni.iTime);
  float3 pos=org+dir*t;
  float3 nor=calcNormal(pos, bounce, uni.iTime);
  
  // 	lighting:
  float3 lig=normalize(float3(.2,6.,.5));
  //	scene depth
  float depth=saturate((1.-0.09*t));
  
  //   float3 pos2 = float3(0.);
  float3 nor2 = float3(0.);
  if(t<12.0)
  {
    color2 = float3(max(dot(lig,nor),0.)  +  pow(max(dot(reflect(dir,nor),lig),0.),16.));
    color2 *=saturate(softshadow(pos,lig, bounce, uni.iTime));  // shadow
    float t2;
    color2.rgb +=refr(pos,lig,dir,nor,0.9, t2, nor2, bounce, uni.iTime)*depth;
    color2-=saturate(.1*t2);				// inner intensity loss
    
  }
  
  
  float tmp = 0.;
  float T = 1.;
  
  //	animation of glow intensity
  float intensity = 0.1*-sin(.209*uni.iTime+1.)+0.05;
  for(int i=0; i<128; i++)
  {
    float density = 0.; float nebula = noisePerlin(org+bounce);
    density=intensity-map(org+.5*nor2, bounce, uni.iTime)*nebula;
    if(density>0.)
    {
      tmp = density / 128.;
      T *= 1. -tmp * 100.;
      if( T <= 0.) break;
    }
    org += dir*0.078;
  }    
  float3 basecol=float3(1./1. ,  1./4. , 1./16.);
  T=clamp(T,0.,1.5);
  color += basecol* exp(4.*(0.5-T) - 0.8);
  color2*=depth;
  color2+= (1.-depth)*noisePerlin(6.*dir+0.3*uni.iTime)*.1;	// subtle mist
  
  
  //	scene depth included in alpha channel
  fff.pass1 = float4(float3(1.*color+0.8*color2)*1.3,abs(0.67-depth)*2.+4.*wobble);

  return fff;

}
