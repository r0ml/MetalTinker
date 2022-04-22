/**
 Author: PauloFalcao
 Use Your Mouse!!! And change MAXAA in BufA

 A variation of Cubes and Spheres (black and white version)
 With stochastic sampling anti-aliasing
 Using buffers for accumulation

 Original made in Jan 2012 for glslsandbox - http://glslsandbox.com/e#1215.0

 */
#define shaderName Black_and_White_Spheres

#include "Common.h"

#define MAXAA 32.0


class shaderName {
public:

  //Util Start

  float2 ObjUnion(
                  const float2 obj0,
                  const float2 obj1)
  {
    if (obj0.x<obj1.x)
      return obj0;
    else
      return obj1;
  }

  float2 sim2d(
               const float2 p,
               const float s)
  {
    float2 ret=p;
    ret=p+s/2.0;
    ret=fract(ret/s)*s-s/2.0;
    return ret;
  }

  float3 stepspace(
                   const float3 p,
                   const float s)
  {
    return p-mod(p-s/2.0,s);
  }

  float3 phong(
               const float3 pt,
               const float3 prp,
               const float3 normal,
               const float3 light,
               const float3 color,
               const float spec,
               const float3 ambLight)
  {
    float3 lightv=normalize(light-pt);
    float diffuse=dot(normal,lightv);
    float3 refl=-reflect(lightv,normal);
    float3 viewv=normalize(prp-pt);
    float specular=pow(max(dot(refl,viewv),0.0),spec);
    return (max(diffuse,0.0)+ambLight)*color+specular;
  }

  float2 rand3d_2d(float3 co){
    return float2(
                  fract(sin(dot(co.xyz,float3(27.2344,98.2142,57.2324)))*43758.5453)-0.5,
                  fract(cos(dot(co.xyz,float3(34.7483,42.8534,12.1234)))*53978.3542)-0.5);
  }

  //Util End

  //Scene Start

  float2 obj( float3 p)
  {
    float3 fp=stepspace(p,2.0);;
    float d=sin(fp.x*0.3+0.5*4.0)+cos(fp.z*0.3+0.5*2.0);
    p.y=p.y+d;
    p.xz=sim2d(p.xz,2.0);
    float c1=length(max(abs(p)-float3(0.6,0.6,0.6),0.0))-0.35;
    float c2=length(p)-1.0;
    float cf=sin(0.5)*0.5+0.5;
    return float2(mix(c1,c2,cf),1.0);
  }

  float3 obj_c( float3 p){
    p=fract((p+1.0)/4.0);
    p.x=p.x>.5?-p.x:p.x;
    p.x=p.z>.5?-p.x:p.x;
    return p.x>.0?float3(0):float3(1);
  }

  //Scene End

  float raymarching(
                    const float3 prp,
                    const float3 scp,
                    const int maxite,
                    const float precis,
                    const float startf,
                    const float maxd,
                    thread float& objid)
  {
    //  const float3 e=float3(0.1,0,0.0);
    float2 s=float2(startf,0.0);
    float3 p;
    float f=startf;
    for(int i=0;i<256;i++){
      if (abs(s.x)<precis||f>maxd||i>maxite) break;
      f+=s.x;
      p=prp+scp*f;
      s=obj(p);
      objid=s.y;
    }
    if (f>maxd) objid=-1.0;
    return f;
  }


  float3 camera(
                const float time,
                const float3 prp,
                const float3 vrp,
                const float3 vuv,
                const float vpd,
                thread float3& u,
                thread float3& v,
                const float2 winCoord,
                const float2 reso

                )
  {
    float2 rnd=rand3d_2d(float3(winCoord,time));
    float2 vPos=-1.0+2.0*(winCoord+rnd)/reso;
    float3 vpn=normalize(vrp-prp);
    u=normalize(cross(vuv,vpn));
    v=cross(vpn,u);
    float3 scrCoord=prp+vpn*vpd+vPos.x*u*reso.x/reso.y+vPos.y*v;
    return normalize(scrCoord-prp);
  }

  float3 normal(const float3 p)
  {
    //tetrahedron normal
    const float n_er=0.01;
    float v1=obj(float3(p.x+n_er,p.y-n_er,p.z-n_er)).x;
    float v2=obj(float3(p.x-n_er,p.y-n_er,p.z+n_er)).x;
    float v3=obj(float3(p.x-n_er,p.y+n_er,p.z-n_er)).x;
    float v4=obj(float3(p.x+n_er,p.y+n_er,p.z+n_er)).x;
    return normalize(float3(v4+v1-v3-v2,v3+v4-v1-v2,v2+v4-v3-v1));
  }

  float3 render(
                const float3 prp,
                const float3 scp,
                const int maxite,
                const float precis,
                const float startf,
                const float maxd,
                const float3 background,
                const float3 light,
                const float spec,
                const float3 ambLight,
                thread float3& n,
                thread float3& p,
                thread float& f,
                thread float& objid)
  {
    objid=-1.0;
    f=raymarching(prp,scp,maxite,precis,startf,maxd,objid);
    if (objid>-0.5){
      p=prp+scp*f;
      float3 c=obj_c(p);
      n=normal(p);
      float3 cf=phong(p,prp,n,light,c,spec,ambLight);
      return float3(cf);
    }
    f=maxd;
    return float3(background); //background color
  }
};


// Black and White Spheres / Cubes with anti-aliasing and dof using buffers
// by @paulofalcao
//
// Original made in Jan 2012 for glslsandbox
//
// http://glslsandbox.com/e#1215.0
// 
// ================================
//
// A variation of Cubes and Spheres (black and white version)
// With stochastic sampling anti-aliasing
// Using the backbuffer for acumulation
//
// I love Monte Carlo rendering tecniques! :)
//

fragmentFn(texture2d<float> lastFrame) {
  shaderName shad;

  // Black and White Spheres / Cubes with anti-aliasing and dof using buffers
  // by @paulofalcao
  //
  // Original made in Jan 2012 for glslsandbox
  //
  // http://glslsandbox.com/e#1215.0
  //
  // ================================
  //
  // A variation of Cubes and Spheres (black and white version)
  // With stochastic sampling anti-aliasing
  // Using the backbuffer for acumulation
  //
  // I love Monte Carlo rendering tecniques! :)
  //



  float time=mod(uni.iTime,20.0);//After some time some artifacts appear

  float2 position = ( thisVertex.where.xy / uni.iResolution.xy );
  float4 backpixel = lastFrame.sample(iChannel0, position);

  //Camera animation
  const float3 vuv=float3(0,1,0);
  const float3 vrp=float3(0.0,0.0,0.0);

  float mx=uni.iMouse.x*PI*2.0;
  float my=uni.iMouse.y*PI/2.01;
  
  //1st img fix
  if (mx==0.0) mx=4.0; if (my==0.0) my=0.45;
  
  
  float3 prp=vrp+float3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*12.0; //Trackball style camera pos
  const float vpd=2.0;
  float3 light=prp+float3(5.0,0,5.0);
  
  
  float3 u,v;
  float3 scp=shad.camera(time,prp,vrp,vuv,vpd,u,v, thisVertex.where.xy, uni.iResolution);

  //Depth of Field using a flat field lens and disk sampling for circle of confusion
  //
  //The focus is a plane, i think it's nice this way
  //The focus can also be curved using just the distance to the camera
  //Or just a point
  //
  //8bits color depth is not the best for this kind of stuff :(
  //We need a floating point target for pretty bokeh and better convergence...
  //
  // UPDATE 2016 with Shadertoy - Now we have floating point targets!!! :)
  //
  float3 vp=vrp-prp;
  float3 focuspoint=prp+scp*(dot(vp,vp)/dot(vp,scp)); //flat field lens
  float2 rnd=shad.rand3d_2d(float3(position*time,time))+0.5;
  rnd.y*=PI*2.0;
  rnd=float2(sqrt(rnd.x)*cos(rnd.y),sqrt(rnd.x)*sin(rnd.y))*0.5; //random disk
  prp=prp+scp*1.0+rnd.x*u+rnd.y*v;
  scp=normalize(focuspoint-prp);

  float3 n,p;
  float f,o;
  const float maxe=0.01;
  const float startf=0.1;
  const float3 backc=float3(0.0,0.0,0.0);
  const float spec=8.0;
  const float3 ambi=float3(0.1,0.1,0.1);
  
  float3 c1=shad.render(prp,scp,256,maxe,startf,60.0,backc,light,spec,ambi,n,p,f,o);
  c1=c1*max(1.0-f*.015,0.0);
  float3 c2=backc;
  if (o>0.5){
    scp=reflect(scp,n);
    c2=shad.render(p+scp*0.05,scp,32,maxe,startf,10.0,backc,light,spec,ambi,n,p,f,o);
  }
  c2=c2*max(1.0-f*.1,0.0);
  return float4(c1.xyz*0.75+c2.xyz*0.25,1.0)*(1.0/MAXAA)+backpixel*((MAXAA-1.0)/MAXAA);
}
