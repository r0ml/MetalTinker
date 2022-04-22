
#define shaderName ruffled_wing

#include "Common.h"

initialize() {}

#define SegNum 48

class shaderName {
public:
  
  texture2d<float> inTexture;
  float time;
  
  float motion = 0.;
  
  float4 multQuat(float4 a, float4 b)
  {
    return float4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz));
  }
  
  float4 rotateQuatbyAngle(float4 quat, float3 angle)
  {
    float angleScalar=length(angle);
    if (angleScalar<0.00001) return quat;
    return multQuat(quat,float4(angle*(sin(angleScalar*0.5)/angleScalar),cos(angleScalar*0.5)));
  }
  
  float3 transformVecByQuat( float3 v, float4 q )
  {
    return v + 2.0 * cross( q.xyz, cross( q.xyz, v ) + q.w*v );
  }
  
  float getRand(float x)
  {
//    return getTexRand(float2(mod(x,64.),floor(x/64.))).y;
    return interporand(float2(mod(x, 64), floor(x/64.))).y;
  }
  
  float sFade(float xf, float w, float v1, float v2, float x)
  {
    return mix(v1,v2,saturate((x-xf+w)/2./w));
  }
  
  float wingFunc(float x)
  {
    return sFade(0.4,0.15,-.3,.7,x);
  }
  
  float3 distArcE(float2 pos, float2 p0, float2 dir, float curve, float len)
  {
    float r = 1.0/curve;
    float2 pc = p0+dir.yx*float2(1,-1)*r;
    float ang0=atan2(-(p0-pc).y*sign(r),(p0-pc).x);
    float ang=atan2(-(pos-pc).y*sign(r),(pos-pc).x);
    // float ang2=ang; //if(ang<ang0-PI) ang+=TAU;
    float ang1=ang0+len/abs(r);
    if(ang<.5*(ang0+ang1)-PI) ang+=TAU;
    if(ang>.5*(ang0+ang1)+PI) ang-=TAU;
    if(ang>ang0 && ang<ang1)
      return float3(abs(length(pos-pc)-abs(r)),(length(pos-pc)-abs(r)),(ang-ang0)/(ang1-ang0));
    float2 p1 = pc+abs(r)*float2(cos(ang1),-sin(ang1)*sign(r));
    float d=100000.;
    d=min(d,length(pos-p0));
    d=min(d,length(pos-p1));
    return float3(d,(length(pos-pc)-abs(r)),(ang-ang0)/(ang1-ang0));
  }
  
  float3 getDistE(float2 coord, float2 mouse, int buttons, int frame) {
    float growFact = saturate(time*.1);
    growFact=1.;

    //if(uni.iMouse.x==0. && uni.iMouse.y==0.) mouse=0.1*float2(-.5-sin(3.*uni.iTime),3.*cos(3.*uni.iTime));
    if (!buttons) mouse=0.02*float2(-.5-sin(3.*time),3.*cos(3.*time));
    if (frame<10) mouse=float2(0);
    
    float d=100000.0;
    float3 p0=float3(5,150,0);
    //  float4 q0=float4(0,0,0,1);
    float4 dq0;
    float4 dq1;
    float3 dp0=float3(6.*cos(mouse.x),6.*sin(mouse.x),0)*growFact*growFact;
    //  float3 dp1=float3(1.5*cos(sin(uni.iTime)),1.5*sin(sin(uni.iTime)),0);
    float2 wingCoord=float2(0);
    float wingSum=0.;
    float2 uv=float2(0);
    for(int i=0;i<SegNum;i++)
    {
      p0+=dp0;
      float wingArg = float(i)/float(SegNum)*growFact;
      float wingDiff = .005*(wingFunc(wingArg)-wingFunc(wingArg+.001))/.001;
      dq0=rotateQuatbyAngle(float4(0,0,0,1), float3(0,0,1)
                            *(.05*wingFunc(wingArg)-wingDiff*(1.3+5.*mouse.y))
                            );
      dp0 = transformVecByQuat(dp0,dq0);
      float3 p1=p0;
      float rnd=getRand(float(i)+time);
      float3 dp1 = (0.2+float(i*i)*.00025+.5*clamp(getRand(float(i+123)),-.2,.5))*transformVecByQuat(dp0,
                                                                                                     rotateQuatbyAngle(float4(0,0,0,1),
                                                                                                                       float3(0,0,-70.+float(i)*(.7-.3*mouse.y)-rnd*0.0)/180.*PI));
      dp1*=growFact;
      dq1=rotateQuatbyAngle(float4(0,0,0,1), float3(0,0,-0.02+float(i)*0.0001
                                                    +.75*sin(1.2*float(i)+3.9)*0.01)
                            +.75*(.04+motion)*sin(time*5.+1.2*float(i))*0.01);
      
      float3 d2=distArcE(coord,
                         p1.xy,
                         normalize(dp1.xy),
                         -2.*dq1.z/length(dp1.xy)+.005*wingArg*mouse.x,
                         length(dp1)*float(SegNum));
      
      float2 uv2=d2.yz*float2(.1/float(SegNum),1)+float2(i,0)/float(SegNum);
      float rnd2=(inTexture.sample(iChannel0,uv2*float2(2.,.04)).x-.5);
      rnd2=rnd2*.7+.3*(inTexture.sample(iChannel0,uv2*float2(2.,.04)*3.).x-.5);
      rnd2=rnd2*.8+.2*(inTexture.sample(iChannel0,uv2*float2(2.,.04)*9.).x-.5);
      d2.x+=20.*rnd2*(.3+2.*uv2.y);
      if(d2.x<d) { d=d2.x; uv=uv2; }
    }
    wingCoord/=wingSum;
    return float3(d,uv);
  }
};

fragmentFn1() {
  shaderName shad;
  shad.inTexture = renderInput[0];
  shad.time = uni.iTime;
  
  FragmentOutput f;
  float2 uv = thisVertex.where.xy/uni.iResolution.xy;
  f.fragColor = renderInput[0].sample(iChannel0,uv);
  
  // ============================================== buffers =============================

  float2 pos = thisVertex.where.xy*300./uni.iResolution.y;
  f.pass1.xyz=float3(abs(shad.getDistE(pos, uni.iMouse.xy*2.-1., uni.mouseButtons, uni.iFrame).x*.05-1.));
  return f;
}
