
#define shaderName Foggy_Road

#include "Common.h"

constexpr sampler chan(coord::normalized, address::repeat, filter::linear, mip_filter::linear);


#define BLUR_SAMPLES 16
#define BLUR_SIZE .01
#define BLOOM_INTENSITY 1.5

#define MAX_ITERATIONS 512
#define MIN_DISTANCE  .001

#define LIGHT_INT .43
#define LIGHT_COL float3(192.,192.,240.) / (255./LIGHT_INT)
#define LIGHT_DIR normalize(float3(25.,25.,55.))

struct Ray { float3 ori; float3 dir; };
struct Dst { float dst; int id;  };
struct Hit { float3 p; int id;    };

static Dst dstFloor(float3 p, float y, texture2d<float> tex0) {

  float d = tex0.sample(chan, mod(p.xz,1.)).x * .01;
  if(p.x > 1. && p.x < 9.) {
    y -= .25;
  }
  return Dst { p.y - y - max(d,0.), 0 } ;
}

// Source: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
static Dst sdCappedCylinder( float3 p, float2 h) {

  float3 q  = p;
  float c = 5.5;
  q.z   = mod(q.z,c)-.5*c;

  float2 d = abs(float2(length(q.xz),q.y)) - h;
  float dst = min(max(d.x,d.y),0.0) + length(max(d,0.0));

  return Dst { dst,1 } ;
}

static Dst sdBuilding(float3 p, float3 b) {

  float3 q  = p;
  float c = 3.25;
  q.z    = mod(q.z,c)-.5*c;

  return Dst { length(max(abs(q)-b,0.0)), 2 } ;

}

static Dst dstUnion(Dst a, Dst b) {

  if(a.dst < b.dst) return a;
  return b;

}

static Dst dstScene(float3 p, texture2d<float> tex0) {

  Dst dst = dstFloor(p, 0., tex0);
  dst   = dstUnion(dst, sdCappedCylinder(p, float2(.2,5.)));
  dst    = dstUnion(dst, sdBuilding(p+float3(4.,0.,0.),float3(1.,2.5,1.)));
  dst   = dstUnion(dst, sdCappedCylinder(p-float3(10.,0.,0.), float2(.2,5.)));
  dst    = dstUnion(dst, sdBuilding(p-float3(14.,0.,0.),float3(1.,2.5,1.)));

  return dst;

}

static Hit raymarch(Ray ray, int maxIter, float maxDst, texture2d<float> tex0) {

  float3 p = ray.ori;
  int id = -1;

  for(int i = 0; i < MAX_ITERATIONS; i++) {

    if(i >= maxIter || distance(p,ray.ori) >= maxDst) {

      id = -1;
      break;

    }

    Dst scn = dstScene(p, tex0);
    p += ray.dir * scn.dst * .75;

    if(scn.dst < MIN_DISTANCE) {

      id = scn.id;
      break;

    }

  }

  return Hit { p,id } ;

}

static float3 getSky(float3 dir, float time) {

  float randx = rand( dir.yx*time*.5);
  float3 stars = pow( interporand(6.*dir.xy, 256).xxx,float3(12.))*randx;
  float3 moon  = float3(0.);

  if(max(pow(dot(dir,LIGHT_DIR),360.),0.) > .7) {
    moon = float3(2.)*rand(dir.xy*.5);
  }

  return mix(float3(1.),stars,pow(dir.y+.1,.1))+moon;

}

static float3 calcFog(Ray ray, float3 p, float3 col) {

  float fog = smoothstep(15., 45., distance(ray.ori,p));
  fog *= 1.-smoothstep(0.,.25,ray.dir.y);

  return mix(col, float3(1.)*LIGHT_COL, fog);

}

static float3 calcNormal(float3 p, texture2d<float> tex0) {

  float2 eps = float2(.001,0.);
  float3 n   = float3(dstScene(p+eps.xyy, tex0).dst-dstScene(p-eps.xyy, tex0).dst,
                      dstScene(p+eps.yxy, tex0).dst-dstScene(p-eps.yxy, tex0).dst,
                      dstScene(p+eps.yyx, tex0).dst-dstScene(p-eps.yyx, tex0).dst);
  return normalize(n);

}

static float calcFresnel(Ray ray, float3 n, float power) {

  return 1. - max(pow(-dot(ray.dir,n), power), 0.);

}

// Source: https://www.shadertoy.com/view/Xds3zN
// Modified by jackdavenport
static float softshadow( const float3 ro, const float3 rd, const float mint, const float tmax, float softness, texture2d<float> tex0 )
{
  float res = 1.0;
  float t = mint;
  for( int i=0; i<32; i++ )
  {
    float h = dstScene( ro + rd*t, tex0 ).dst;
    res = min( res, softness*h/t );
    t += clamp( h, 0.02, 0.40 );
    if( h<0.001 || t>tmax ) break;
  }
  return saturate( res);

}

static float3 calcLighting(float3 col, float3 p, float3 n, float3 r, float shine, texture2d<float> tex0) {

  float d = max(dot(LIGHT_DIR,n), 0.);
  float s = 0.;

  if(shine > 0.) {
    s = max(pow(dot(LIGHT_DIR,r), shine), 0.);
  }

  d *= softshadow(p+LIGHT_DIR*.01,LIGHT_DIR,0.,256.,64., tex0);

  return (col*LIGHT_COL*d)+(s*d*LIGHT_COL);

}

static float3 shadeGround(Hit scn, float3 n, float3 r, float3 t, texture2d<float> tex0) {

  return calcLighting(t, scn.p, n, r, mix(25.,45.,pow(t.x,3.)), tex0);

}

static float3 shadePole(Hit scn, float3 n, float3 r, texture2d<float> tex0, texture2d<float> tex1) {

  float2 uv = mod(asin(n.xz) / PI + .5, 1.);
  float3 c  = tex1.sample(chan, uv).xyz;

  return calcLighting(c, scn.p, n, r, 25., tex0);

}

static float3 shadeBuilding(Hit scn, float3 n, float3 r, texture2d<float> tex0) {

  float3 c = float3(1.);
  return calcLighting(c, scn.p, n, r, 0., tex0);

}

static float3 getReflection(float3 p, float3 r, float time, texture2d<float> tex0, texture2d<float> tex1) {

  Ray rr  = Ray { p+r*.01,r } ;
  Hit rh  = raymarch(rr,128,256., tex0);
  float3 rc = float3(0.);
  if(rh.id == 0) {
    float3 rn = calcNormal(rh.p, tex0);
    float3 rd = normalize(reflect(rr.dir,rn));
    rc = shadeGround(rh,rn,rd,tex0.sample(chan,mod(p.xz,1.)).xyz, tex0);
  } else if(rh.id == 1) {
    float3 rn = calcNormal(rh.p, tex0);
    float3 rd = normalize(reflect(rr.dir,rn));
    rc = shadePole(rh,rn,rd,tex0, tex1);
  } else if(rh.id == 2) {
    float3 rn = calcNormal(rh.p, tex0);
    float3 rd = normalize(reflect(rr.dir,rn));
    rc = shadeBuilding(rh,rn,rd, tex0);
  } else {
    rc = getSky(r, time);
  }

  return calcFog(rr,rh.p,rc);

}

static float3 shade(Ray ray, float time, texture2d<float> tex0, texture2d<float> tex1) {

  Hit scn  = raymarch(ray, MAX_ITERATIONS, 75., tex0);
  float3 col = float3(0.);

  if(scn.id == 0) {

    float3 t = tex0.sample(chan, mod(scn.p.xz,1.)).xyz;
    float3 n = calcNormal(scn.p, tex0);
    float3 r = normalize(reflect(ray.dir,n));

    col   = shadeGround(scn,n,r,t, tex0);
    float3 rc = getReflection(scn.p, r, time, tex0, tex1);

    float f = calcFresnel(ray, n, .2);
    col = mix(col, rc, f);
    //col = float3(f);

  } else if(scn.id == 1) {

    float3 n = calcNormal(scn.p, tex0);
    float3 r = normalize(reflect(ray.dir,n));

    col   = shadePole(scn,n,r, tex0, tex1);
    float3 rc = getReflection(scn.p, r, time, tex0, tex1);

    float f = calcFresnel(ray, n, .4);
    col = mix(col, rc, f);

  } else if(scn.id == 2) {

    float3 n = calcNormal(scn.p, tex0);
    float3 r = normalize(reflect(ray.dir,n));

    col = shadeBuilding(scn, n, r, tex0);

  } else {

    col = getSky(ray.dir, time);

  }

  col = calcFog(ray, scn.p, col);

  float flare = max(pow(dot(ray.dir,LIGHT_DIR), 90.), 0.);
  col += LIGHT_COL * flare * softshadow(ray.ori,LIGHT_DIR,0.,256.,16., tex0);

  return col;

}

fragmentFn(texture2d<float> lastFrame, texture2d<float> tex) {
  float2 uv = (thisVertex.where.xy - uni.iResolution.xy * .5) / uni.iResolution.y;
  uv.y = -uv.y;

  float3 ori = float3(-1., .4, -4.+uni.iTime*.25);
  float3 dir = float3(uv, 1.);
  Ray  ray = Ray { ori,normalize(dir) } ;

  if (uni.wasMouseButtons) {
    ray.ori.xy += float2(.5,1.)*(uni.iMouse.xy*2.-1.);
    ray.ori.y	= max(ray.ori.y, .1);
  }

  return float4(shade(ray, uni.iTime, lastFrame, tex),1.);
}
