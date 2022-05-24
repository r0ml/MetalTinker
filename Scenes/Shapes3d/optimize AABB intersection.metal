
#define shaderName optimize_aabb_intersection

#include "Common.h" 

struct InputBuffer {};
initialize() {}

#define minT(a,b) (a<b)? zfar: (b<0.)? (a>0.)? a: zfar: b
#define vec3max(a) max(a.x, max(a.y, a.z))
#define vec3min(a) min(a.x, min(a.y, a.z))

struct ray { float3 o, d; };
struct hit { float3 l, n; float d; };
struct box { float3 c, s; }; //center and size (instead of 2 corners), happens to be intuitive for me and produce shorter code

hit lt( hit a,  hit b) { if (a.d < b.d) return a; else return b; }

constant const box b1 = box {float3(-3.,0.,5.), float3(1.,1.,10.)},
b2 = box {float3(0.,0.,5.), float3(1.,1.,10.)},
b3 = box {float3(3.,0.,5.), float3(1.,1.,10.)},
b4 = box {float3(-2.,3.,5.), float3(1.,1.,10.)},
b5 = box {float3(2.,3.,5.), float3(1.,1.,10.)};

constant const float zfar = 1000.;

static hit traceBox( ray r,  box b) {
  float3 t1 = (b.c-b.s - r.o)/r.d, //https://www.siggraph.org/education/materials/HyperGraph/raytrace/rtinter3.htm
  t2 = (b.c+b.s - r.o)/r.d,
  tn = min(t1, t2), tx = max(t1, t2);
  float d = minT(vec3min(tx),vec3max(tn)); //minT calculates the minimum positive, if n/a then returns zfar
  float3 l = r.o + r.d * d,
  a = l - b.c; //location relative to box center
  return hit {l, step(b.s*.995, abs(a)) * sign(a), d }; //for the normal, use step(size, loc)
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted;
  float4 fragColor = float4(0.);
  ray r = { float3(sin(uni.iTime)*2., 1.2, -10.), normalize(float3(uv,1.)) };
  hit h = traceBox(r, b1);
  h = lt(h, traceBox(r, b2));
  h = lt(h, traceBox(r, b3));
  h = lt(h, traceBox(r, b4));
  h = lt(h, traceBox(r, b5));
  if (h.d < zfar) fragColor.rgb = abs(h.n); //shade absolute normal
  else fragColor.bg = abs(uv); //background
  fragColor.w = 1;
  return fragColor;
}
