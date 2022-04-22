
#define shaderName Contained

#include "Common.h"

// ============================================= common =================================

#define SCALE 3.



#define parts 400


constant static const float fov = 750.;

static float ls(float2 u, float2 s, float2 e)
{
  float2 l1 = u-s;
  float2 l2 = (e-s)*(clamp( dot(l1,(e-s) ) /(dot(e-s,e-s)), 0., 1. ) );
  
  return 1.-smoothstep(1.5,1.6,length(l1-l2));
}

static float sq(float2 f,float w,float r,float d){
  float a = 0.;
  float3 p = float3(1);
  float s = sin(r),c = cos(r);
  
  float3 lj = float3(0);
  
  for(int i = 0; i < 5; i++)
  {
    float3 j = p*w;
    j.xz = j.xz * float2x2(c,s,-s,c);
    j.z-=d;
    j.xy/=j.z;
    j.xy*=fov;
    if(i<5)
      a+=ls(f,j.xy,j.xy*float2(1,-1));
    if(i > 0)
    {
      a+=ls(f,j.xy,lj.xy);
      a+=ls(f,j.xy*float2(1,-1),lj.xy*float2(1,-1));
    }
    p.xz = p.zx;
    p.z*=-1.;
    lj = j;
  }
  
  return a;
}


fragmentFn() {
  FragmentOutput fff;
  fff.fragColor = renderInput[0].sample(iChannel0,thisVertex.where.xy/uni.iResolution.xy/SCALE).araa;
  //c = floor(c*16.)/16.;
  fff.fragColor.w = 1;
  
  // ============================================== buffers =============================
  
  if(thisVertex.where.x < uni.iResolution.x/SCALE && thisVertex.where.y < uni.iResolution.y/SCALE)
  {
    float2 fr = thisVertex.where.xy + uni.iResolution.xy/(SCALE*2.);
    float3 col = float3(0);
    
    float2 f = 1000.*(fr -= uni.iResolution.xy/(SCALE))/uni.iResolution.x*SCALE;
    
    float r = uni.iTime*.3+5.*sin(.3*uni.iTime);
    float s = sin(r),c = cos(r);
    float w = smoothstep(5.,0.,uni.iTime)*1000. + 300.;
    float d = 1600.+200.*cos(uni.iTime*.6);
    float sb = smoothstep(3.,7.,uni.iTime);
    
    col += sb*sq(f,w,r,d);
    
    for(int i = 0; i < parts; i++)
    {
      float3 dat = w*sin(float3(5322,6344,6436)*float(i)*0.0001+.1*uni.iTime);
      dat.xz = dat.xz * float2x2(c,s,-s,c);
      dat.z-=d;
      dat.xy/=dat.z;
      dat.xy*=fov;
      float b = .19*smoothstep(0.,3.,uni.iTime);
      if(dat.z < 0.)
      {
        col += b*(1.+( max((dat.z+1500.)/500.,-.6) ) )/(length(f-dat.xy));//*(.5+.5*sin(float3(2.,1.4,1.8)*dat.w+uni.iTime));
        dat.xy *= 3.4;
        col += b*(1.+( max((dat.z+1500.)/500.,-.6) ) )/(length(f-dat.xy));
      }
    }
    
    fff.pass1 = float4(pow(col,float3(4)),0)+.3*renderInput[0].sample(iChannel0,thisVertex.where.xy/uni.iResolution.xy);
    
  }
  return fff;
}

