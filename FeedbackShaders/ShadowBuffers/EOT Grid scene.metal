/** 
 Author: Virgill
 End of time by Alcatraz & Altair - grid scene.
 Full intro: http://www.pouet.net/prod.php?which=77102
 introducing Madtracer [tm]


 */
#define shaderName EOT_Grid_scene

#include "Common.h"

//------------------------------------------------------------------------
//  End of time.  A 4k intro by Virgill/Alcatraz & KK/Altair
//
//  Full intro: http://www.pouet.net/prod.php?which=77102
//  Youtube: https://youtu.be/5lR76o9lWB0
//
//  Thanks to these ppl for help + inspiration: Slerpy, LJ, Xtr1m, Gopher
//------------------------------------------------------------------------

//------------------------------------------------------------------------
//  End of time.  A 4k intro by Virgill/Alcatraz & KK/Altair
//
//  Full intro: http://www.pouet.net/prod.php?which=77102
//  Youtube: https://youtu.be/5lR76o9lWB0
//
//  Thanks to these ppl for help + inspiration: Slerpy, LJ, Xtr1m, Gopher
//------------------------------------------------------------------------

class shaderName {
public:

float3 scol;

void dmin(thread float3& d, float x, float y, float z)
{
  if(x<d.x) d=float3(x,y,z);
}

// 3D noise function (IQ, Shane)
float noise(float3 p)
{
  float3 ip=floor(p);
  p-=ip;
  float3 s=float3(7, 157, 113);
  float4 h=float4(0., s.yz, s.y+s.z)+dot(ip, s);
  p=p*p*(3.-2.*p);
  h=mix(fract(sin(h)*43758.5), fract(sin(h+s.x)*43758.5), p.x);
  h.xy=mix(h.xz, h.yw, p.y);
  return mix(h.x, h.y, p.z);
}

// hemisphere hash function based on a hash by Slerpy
float3 hashHs(float3 n, float seed)
{
  float a = fract(sin(seed)*43758.5)*2.-1.;
  float b = TAU*fract(sin(seed)*41758.5)*2.-1.;
  float c=sqrt(1.-a*a);
  float3 r=float3(c*cos(b), a, c*sin(b));
  return r;
}

float box(float2 p)
{
  p=abs(p); return max(p.x, p.y);
}

float3 map(float3 p, const float time) {
  float3 q;
  float3 d = float2(0, 1.).yxx;
  // float floornoise = .8*noise(3.*p+2.3*time)+0.1*noise(20.*p+2.2*time);
  dmin(d, min(5.-p.z, 1.5+p.y), 0.1+0.3*step(mod(4.*p.z, 1.), .5), .0);
  dmin(d, length(p+float3(0., 0., 1.9+sin(time)))-.500, .99, 1.);
  q=p;
  q.xy = q.xy * rot2d(0.6*time);

  dmin(d, length(q+float3(0, 0., 1.9+sin(time)))-.445-0.09*sin(43.*q.x-q.y+10.*time), 1., 0.1);
  if( time>24. )p.y-=0.1*time-2.4;
  q = abs(p-round(p-.5)-.5);
  if( time>24. )p.y+=0.1*time-2.4;
  float g = min(min(box(q.xy), box(q.xz)), box(q.yz))-.05;
  float c = min(.6-abs(p.x+p.z), .45-abs(p.y));
  if (time>12.) dmin(d, max(g, c), .1, 0.5); //lattice (by Slerpy)

  if( time>18. )dmin(d, box(p.zx+float2(2, 2))-.5, 1., .4);
  if( time>17.3)dmin(d, box(p.zx+float2(2,-2))-.5, 1.,-.4);
  return d;

}


float3 normal(float3 p, const float time)
{
  float m = map(p, time).x;
  float2 e = float2(0,.05);
  return normalize(m-float3(map(p - e.yxx, time).x, map(p - e.xyx, time).x, map(p - e.xxy, time).x));
}


void madtracer( float3 ro1, float3 rd1, float seed, const float time) {
  scol = float3(0);
  float t = 0., t2 = 0.;
  float3 m1, m2, rd2, ro2, nor2;
  float3 roold=ro1;
  float3 rdold=rd1;
  m1.x=0.;
  for( int i = 0; i < 140; i++ ) {
    seed = fract(seed+time*float(i+1)+.1);
    ro1=mix(roold, hashHs(ro1, seed), 0.002);        // antialiasing
    rd1=mix(rdold, hashHs(rdold, seed), 0.06*m1.x);      // antialiasing
    m1 = map(ro1+rd1*t, time);
    t+=m1.z!=0. ? 0.25*abs(m1.x)+0.0008 : 0.25*m1.x;
    ro2 = ro1 + rd1*t;
    nor2 = normal(ro2, time);                   // normal of new origin
    seed = fract(seed+time*float(i+2)+.1);
    rd2 = mix(reflect(rd1, nor2), hashHs(nor2, seed), m1.y);// reflect depending on material
    m2 = map(ro2+rd2*t2, time);
    t2+=m2.z!=0. ? 0.25*abs(m2.x) : 0.25*m2.x;
    scol+=.007*(float3(1.+m2.z, 1., 1.-m2.z)*step(1., m2.y)+float3(1.+m1.z, 1., 1.-m1.z)*step(1., m1.y));
  }
}

};

fragmentFn(texture2d<float> lastFrame) {
  shaderName shad;

  const float2 uv = (thisVertex.where.xy/uni.iResolution.xy);

  // borders
  if( uv.y>.1&&uv.y<0.9 ) {
    float seed = sin(thisVertex.where.x + thisVertex.where.y)*sin(thisVertex.where.x - thisVertex.where.y);
    float3 bufa = lastFrame.sample(iChannel0, uv).xyz;

    // camera
    float3 ro, rd;
    float2 uv2 = (2.*thisVertex.where.xy-uni.iResolution.xy)/uni.iResolution.x;
    ro = float3(0, 0,-5);
    rd = normalize(float3(uv2, 1));
    // rotate scene
    if (uni.iTime>12.) {
      rd.xz = rd.xz * rot2d(.5*-sin(.17*uni.iTime));
      rd.yz = rd.yz * rot2d(.5*sin(.19*uni.iTime));
      rd.xy = rd.xy * rot2d(.4*-cos(.15*uni.iTime));
    }
    // render
    shad.madtracer(ro, rd, seed, uni.iTime);

    float fade =min(3.*abs(sin((PI*(uni.iTime-12.)/24.))), 1.);
    return saturate(float4(0.7*shad.scol+0.7*bufa, 0.)*fade); // with blur
  } else {
    return 0;
  }
}
