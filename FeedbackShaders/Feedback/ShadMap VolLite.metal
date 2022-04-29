/** 
Author: eiffie
A demo of using shadow maps of a point light to measure volume light.
*/
#define shaderName ShadMap_VolLite

#include "Common.h"

struct KBuffer { };
initialize() {}

 




//ShadMap VolLite by eiffie
//I'm posting this because I'm always forgetting how to do the transform.

//Place a camera at the point light and record the depths in ALL directions.
//Then march thru the volume light area collecting light samples by comparing
//the distance to the light against the Shadow Map.

//For this demo everything is done in buf A

 //ShadMap VolLite by eiffie
//I'm posting this because I'm always forgetting how to do the transform.
//V2.0 because i DID forget it!

//Place a camera at the point light and record the depths in ALL directions.
//Then march thru the volume light area collecting light samples by comparing
//the distance to the light against the Shadow Map.


//Normally the ShadMap fills buf A then the VolLite piece is done in Image
#define LIGHT_FALLOFF 3.0

float sgn(float x){return (x<0.?-1.:1.);}

float DE(const float3 p){
  float3 ap=abs(p);
  float a=max(ap.x,max(ap.y,ap.z))-1.0;
  float b=min(max(ap.x,ap.y),max(ap.x,ap.z))-0.5;
  return max(a,-b);
}

float3x3 lookat(float3 fw){
  fw=normalize(fw);float3 rt=normalize(cross(fw,float3(0.0,1.0,0.0)));return float3x3(rt,cross(rt,fw),fw);
}


fragmentFn1() {
  FragmentOutput fff;

	float2 uv = thisVertex.where.xy / uni.iResolution.xy;
	fff.fragColor = renderInput[0].sample(iChannel0,uv);

 // ============================================== buffers ============================= 

	uv*=float2(2.0,1.0);//stretch to 2x1
	float3 ro,rd,posLight=float3(0.0,sin(uni.iTime*0.5),0.4*sin(uni.iTime*0.2));
	float maxdepth=6.0;
	bool bShadMap=(uv.x<1.0);
	if(bShadMap){//left side
		uv-=0.5;//center left side at 0
		uv*=float2(TAU,PI);//for spherical projection
		ro=posLight;
		rd=float3(cos(uv.y)*cos(uv.x),sin(uv.y),cos(uv.y)*sin(uv.x));
		maxdepth=LIGHT_FALLOFF;
	}else{//right side
		uv-=float2(1.5,0.5);//center right side at 0
		ro=float3(cos(uni.iTime),sin(uni.iTime*0.3),sin(uni.iTime))*float3(5.0,3.0,3.0);
		rd=normalize(float3(uv,1.0));
		rd=lookat(-ro)*rd;
	}
	
	float t=0.0,d,eps=1.0/uni.iResolution.y; //march to surface
	for(int i=0;i<32;i++){
		t+=d=DE(ro+t*rd);
		if(d<eps*t || t>maxdepth)break;
	}
	
	if(bShadMap){//left side, store shadow map
		t=clamp(t/LIGHT_FALLOFF,0.0,0.99); //this isn't needed for our unclamped float buffer
		fff.pass1=float4(float3(t),1.0);
		return fff;
	}
	
	//right side, brute march thru ray collecting vol light samples compared against shad map
	float3 col=float3(0.0);
	if(d<eps*t)col=float3(0.1*t);
	float dt=maxdepth/32.0;
	maxdepth=t;
	t=dt*rand(rd);
	for(int i=0;i<32;i++){
		float3 p=ro+t*rd;
		float3 L=(p-posLight);//light direction for shadow lookup
		d=length(L);
		if(d<LIGHT_FALLOFF){//ignore if light is too far away
			L/=d;//normalize
			float phi=asin(L.y);//transform back to 2d
			float2 pt=float2(asin(L.z/cos(phi)),phi);
            if(L.x<0.0)pt.x=sgn(L.z)*PI-pt.x; //I FORGOT THIS AGAIN!!
            pt/=float2(TAU,PI);
			pt+=0.5;//uncenter
			pt*=float2(0.5,1.0);//left side of texture only const this demo
			if(d<renderInput[0].sample(iChannel0,pt).r*LIGHT_FALLOFF){
				col+=float3(1.0,0.9,0.8)/(1.0+10.0*d*d);
			}
		}
		t+=dt;
		if(t>maxdepth)break;
	}
	saturate(col);
	fff.pass1=float4(col,1.0);
  return fff;
}
