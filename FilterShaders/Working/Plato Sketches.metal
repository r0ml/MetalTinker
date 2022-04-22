
// FIXME: completely broken
#define shaderName Plato_Sketches

#include "Common.h"

initialize() {}

//This is where the math should be.. somewhere here
#define load(a) renderInput[0].sample(iChannel0,float2(a+0.5)/uni.iResolution.xy)
#define MAX_VERTS 48
float Tube(float2 pa, float2 ba){return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0));}
float scrib(float3 P){float2 p=float2(2.0*P.x+3.0*P.y-P.z,(P.x-2.0*P.y+0.5*P.z)*50.0)/64.0;return pow(interporand(float2(p), 256).r,1.5);}


//No math here try Buf A
fragmentFn1() {
  FragmentOutput fff;
  fff.fragColor=thisVertex.where.y<1.0?float4(1.0):renderInput[0].sample(iChannel0,thisVertex.where.xy/uni.iResolution.xy);

  //It is left as a challenge to the reader to create the reciprocal shader that
  //calculates the vertices of the tetrahedron, cube and docedahedron without
  //knowing angles, lengths etc

  float tm=float(uni.iFrame),d=20.0,t1=-20.0,t2=20.0;
  if(thisVertex.where.y<1.0 && mod(tm,500.0)<1.0) {
    fff.pass1=float4(sin(thisVertex.where.x+tm),sin(sin(thisVertex.where.x+3.0)*1276.54),thisVertex.where.x*0.01,0.0);
    return fff;
  }
  int verts=6*int(exp2(mod(float(uni.iFrame/500),5.0)-1.0));
  float2 uv=(2.0*thisVertex.where.xy-uni.iResolution.xy)/uni.iResolution.y*1.5;
  if(verts<6){verts=4;uv*=1.5;}
  float3 N,ro=float3(uv+2.5*float2(sin(2.0*tm),cos(2.0*tm))/uni.iResolution.y,-3.0);
  fff.pass1 = renderInput[0].sample(iChannel0,thisVertex.where.xy/uni.iResolution.xy);
  for(int i=0;i<MAX_VERTS;i++){if(i>=verts)break;
    float4 v2=load(float2(i,0.0));
    if(thisVertex.where.y<1.0){
      if(i!=int(thisVertex.where.x)){
        float r=length(fff.pass1.xyz-v2.xyz);
        if(r<d){
          d=r;fff.pass1.w=float(i);
        }
      }
    } else {
      d=min(d,Tube(uv-v2.xy,load(float2(v2.w,0.0)).xy-v2.xy));
      float t=(dot(v2.xyz,ro)-1.0)/v2.z;
      if(v2.z>0.0){if(t>t1){N=v2.xyz;t1=t;}}else if(t<t2)t2=t;
    }
  }
  if(thisVertex.where.y<1.0){
    float sp=0.8-0.0008*mod(tm,500.0);sp=pow(sp,9.0);
    fff.pass1.xyz+=(fff.pass1.xyz-load(float2(fff.pass1.w,0.0)).xyz)/(d*d)*sp;
    float r=length(fff.pass1.xyz);
    fff.pass1.xyz-=sign(r-1.0)*fff.pass1.xyz/r*sp*(1.0+0.02*float(verts));
  }else{
    d=smoothstep(6.0/uni.iResolution.y,0.0,d)*0.05;
    fff.pass1=float4(1.0)-((float4(1.0)-fff.pass1)*0.95+d);
    thisVertex.where.xy=mod(thisVertex.where.xy,20.0);
    if(min(thisVertex.where.x,thisVertex.where.y)<1.0) fff.pass1.x*=0.98;
    if(t1<t2) fff.pass1=mix(fff.pass1,float4(dot(float3(0.707),N)*0.4+0.45),0.2*pow(max(fract(tm/500.0)-(2.0*uv.y-uv.x)*0.05,0.0),4.0)*scrib(float3(uv,t1)+N));
  }
  return fff;
}
