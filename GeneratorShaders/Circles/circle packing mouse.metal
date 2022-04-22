
#define shaderName circle_packing_mouse

#include "Common.h"

struct InputBuffer {
  float3 size;
  float3 center;
};

initialize() {
  in.size = {0.001, 0.1, 0.3 };
  in.center = {0.01, 0.1, 0.5};
}

static float atan3(float2 a){return atan2(a.y,a.x);}
static float2 cs(float a){return float2(cos(a),sin(a));}
static float2 ff(float a){return float2(fract(a),floor(a));}
static float3 huen(float3 c,float n){return c.z*(c.y*smoothstep(1, 2,abs(mod((c.x * n + float3(0, 2, 1)),n) * 2 - n)));}

static float circle(float2 u,float r,float f, float2 reso) {
  float d=length(u)-r+.002;
  return smoothstep(3/reso.y, -2/reso.y, mix(abs(d),d,f) );
}

static float3 circles(float2 u,float2 s,float h,float2 C, float2 reso) {
  float t=asin(s.x/s.y);//angle for surrounding circle
  float2 f=ff(abs(pi/t)+ 0.01) ;
  t*=1.+f.x/f.y ;
  float i=floor(atan3(rot2d(t - h)*u) * 0.5/t); // i-th circle
  return circle(u-cs(i*t*2.+h)*s.y-C,s.x,1, reso) * huen(float3(i/f.y,1, 0.75), 3);
}

fragmentFn() {
  float2 u= worldCoordAspectAdjusted;

//  float2 m=uni.iMouse.xy;//float2(R,r)  ;
//  m=abs(2*m-1) ;

  float3 c = float3(circle(u, in.center.y, 0, uni.iResolution)) ; //draw center
  float i = floor((min(in.size.y * 2 * ( 1/in.size.y -1)+0.01,length(u) - in.center.y))/(in.size.y * 2)); // i-th layer
  float2 a=float2(1, 2 * i + 1) * in.size.y;
  a.y += in.center.y;
  if (i >= 0) {
    c += circles(u, a, sin(uni.iTime) * in.size.y * i * pi, 0, uni.iResolution); // draw surrounding circles
  }
  return float4(1 - c, 1);
}
