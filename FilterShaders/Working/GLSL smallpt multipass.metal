
#define shaderName GLSL_smallpt_multipass

#include "Common.h"

#define MAXDEPTH 4

// Uncomment to see how many samples never reach a light source
//#define DEBUG

// Not used for now
#define DEPTH_RUSSIAN 2

#define DIFF 0
#define SPEC 1
#define REFR 2
#define NUM_SPHERES 9

class shaderName {
public:
  float rand() { return ::rand(seed++); }

  struct Ray { float3 o, d; };
  struct Sphere {
    float r;
    float3 p, e, c;
    int refl;
  };

  float seed = 0.;
  Sphere lightSourceVolume = Sphere { 20., float3(50., 81.6, 81.6), float3(12.), float3(0.), DIFF } ;
  Sphere spheres[NUM_SPHERES];
  void initSpheres() {
    spheres[0] = Sphere { 1e5, float3(-1e5+1., 40.8, 81.6),	float3(0.), float3(.75, .25, .25), DIFF } ;
    spheres[1] = Sphere { 1e5, float3( 1e5+99., 40.8, 81.6),float3(0.), float3(.25, .25, .75), DIFF } ;
    spheres[2] = Sphere { 1e5, float3(50., 40.8, -1e5),		float3(0.), float3(.75), DIFF } ;
    spheres[3] = Sphere { 1e5, float3(50., 40.8,  1e5+170.),float3(0.), float3(0.), DIFF } ;
    spheres[4] = Sphere { 1e5, float3(50., -1e5, 81.6),		float3(0.), float3(.75), DIFF } ;
    spheres[5] = Sphere { 1e5, float3(50.,  1e5+81.6, 81.6),float3(0.), float3(.75), DIFF } ;
    spheres[6] = Sphere { 16.5, float3(27., 16.5, 47.), 	float3(0.), float3(1.), SPEC } ;
    spheres[7] = Sphere { 16.5, float3(73., 16.5, 78.), 	float3(0.), float3(.7, 1., .9), REFR } ;
    spheres[8] = Sphere { 600., float3(50., 681.33, 81.6),	float3(12.), float3(0.), DIFF } ;
  }

  float intersect(Sphere s, Ray r) {
    float3 op = s.p - r.o;
    float t, epsilon = 1e-3, b = dot(op, r.d), det = b * b - dot(op, op) + s.r * s.r;
    if (det < 0.) return 0.; else det = sqrt(det);
    return (t = b - det) > epsilon ? t : ((t = b + det) > epsilon ? t : 0.);
  }

  int intersect(Ray r, thread float& t, thread Sphere& s, int avoid) {
    int id = -1;
    t = 1e5;
    s = spheres[0];
    for (int i = 0; i < NUM_SPHERES; ++i) {
      Sphere S = spheres[i];
      float d = intersect(S, r);
      if (i!=avoid && d!=0. && d<t) { t = d; id = i; s=S; }
    }
    return id;
  }

  float3 jitter(float3 d, float phi, float sina, float cosa) {
    float3 w = normalize(d), u = normalize(cross(w.yzx, w)), v = cross(w, u);
    return (u*cos(phi) + v*sin(phi)) * sina + w * cosa;
  }

  float3 radiance(Ray r) {
    float3 acc = float3(0.);
    float3 mask = float3(1.);
    int id = -1;
    for (int depth = 0; depth < MAXDEPTH; ++depth) {
      float t;
      Sphere obj;
      if ((id = intersect(r, t, obj, id)) < 0) break;
      float3 x = t * r.d + r.o;
      float3 n = normalize(x - obj.p), nl = n * sign(-dot(n, r.d));

      //float3 f = obj.c;
      //float p = dot(f, float3(1.2126, 0.7152, 0.0722));
      //if (depth > DEPTH_RUSSIAN || p == 0.) if (rand() < p) f /= p; else { acc += mask * obj.e * E; break; }

      if (obj.refl == DIFF) {
        float r2 = rand();
        float3 d = jitter(nl, 2.*PI*rand(), sqrt(r2), sqrt(1. - r2));
        float3 e = float3(0.);
        //for (int i = 0; i < NUM_SPHERES; ++i)
        {
          // Sphere s = sphere(i);
          // if (dot(s.e, float3(1.)) == 0.) continue;

          // Normally we would loop over the light sources and
          // cast rays toward them, but since there is only one
          // light source, that is mostly occluded, here goes
          // the ad hoc optimization:
          Sphere s = lightSourceVolume;
          int i = 8;

          float3 l0 = s.p - x;
          float cos_a_max = sqrt(1. - saturate(s.r * s.r / dot(l0, l0)));
          float cosa = mix(cos_a_max, 1., rand());
          float3 l = jitter(l0, 2.*PI*rand(), sqrt(1. - cosa*cosa), cosa);

          if (intersect(Ray { x, l } , t, s, id) == i) {
            float omega = 2. * PI * (1. - cos_a_max);
            e += (s.e * saturate(dot(l, n)) * omega) / PI;
          }
        }
        float E = 1.;//float(depth==0);
        acc += mask * obj.e * E + mask * obj.c * e;
        mask *= obj.c;
        r = Ray { x, d } ;
      } else if (obj.refl == SPEC) {
        acc += mask * obj.e;
        mask *= obj.c;
        r = Ray { x, reflect(r.d, n) } ;
      } else {
        float a=dot(n,r.d), ddn=abs(a);
        float nc=1., nt=1.5, nnt=mix(nc/nt, nt/nc, float(a>0.));
        float cos2t=1.-nnt*nnt*(1.-ddn*ddn);
        r = Ray { x, reflect(r.d, n) } ;
        if (cos2t>0.) {
          float3 tdir = normalize(r.d*nnt + sign(a)*n*(ddn*nnt+sqrt(cos2t)));
          float R0=(nt-nc)*(nt-nc)/((nt+nc)*(nt+nc)),
          c = 1.-mix(ddn,dot(tdir, n),float(a>0.));
          float Re=R0+(1.-R0)*c*c*c*c*c,P=.25+.5*Re,RP=Re/P,TP=(1.-Re)/(1.-P);
          if (rand()<P) { mask *= RP; }
          else { mask *= obj.c*TP; r = Ray { x, tdir } ; }
        }
      }
    }
    return acc;
  }
};

fragmentFn(texture2d<float> lastFrame) {
  shaderName sn;

  sn.initSpheres();
  float2 st = thisVertex.where.xy / uni.iResolution.xy;
  sn.seed = uni.iTime + uni.iResolution.y * thisVertex.where.x / uni.iResolution.x + thisVertex.where.y / uni.iResolution.y;
  float2 uv = 2. * thisVertex.where.xy / uni.iResolution.xy - 1.;
  float3 camPos = float3((2. * .5*uni.iResolution.xy / uni.iResolution.xy - 1.) * float2(48., 40.) + float2(50., 40.8), 169.);
  float3 cz = normalize(float3(50., 40., 81.6) - camPos);
  float3 cx = float3(1., 0., 0.);
  float3 cy = normalize(cross(cx, cz)); cx = cross(cz, cy);

  // Moving average (multipass code)
  float3 color = lastFrame.sample(iChannel0, st).rgb * float(uni.iFrame);
  color += sn.radiance(shaderName::Ray { camPos, normalize(.53135 * (uni.iResolution.x/uni.iResolution.y*uv.x * cx + uv.y * cy) + cz) } ) ;
  return float4(color/float(uni.iFrame + 1), 1.);
}
