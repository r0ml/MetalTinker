
#define shaderName Animation_Test

#include "Common.h"

struct KBuffer {
  struct {
    struct {
      int OverShoot;
      int Spring;
      int Bounce;
      int Quart;
      int Linear;
      int QuartSine;
      int HalfSine;
    } animation;
  } options;
  struct {
    int3 _2;
    int3 _1;
  } pipeline;
};

initialize() {
  kbuff.options.animation.Quart = 1;
  kbuff.pipeline._1 = {3, 18, 1};
  kbuff.pipeline._2 = {3, 150, 6};
}

//--- Animation Functions ---
static float animation(KBuffer kbuff, float s, float e, float t) {
  if (kbuff.options.animation.OverShoot) {
    return smoothstep(s,e,t) + sin(smoothstep(s,e,t)*pi) * 0.5;
  } else if (kbuff.options.animation.Spring) {
    t = saturate((t - s) / (e - s) );
    return 1.0 - cos(t*pi*6.0) * exp(-t*6.5);
  } else if (kbuff.options.animation.Bounce) {
    t = saturate((t - s) / (e - s) );
    return 1.0 - abs(cos(t*pi*4.0)) * exp(-t*6.0);
  } else if (kbuff.options.animation.Quart) {
    t = saturate((t - s) / (e - s) );
    return 1.0-pow(1.0 - t,4.0);
  } else if (kbuff.options.animation.Linear) {
    t = saturate((t - s) / (e - s) );
    return t;
  } else if (kbuff.options.animation.QuartSine) {
     t = saturate((t - s) / (e - s) );
     return sin(t * pi/2.0);
   } else if (kbuff.options.animation.HalfSine) {
     t = saturate((t - s) / (e - s) );
     return 1.0 - cos(t * pi)*0.5+0.5;
   }
  // should never get here
  return 0;
}

// hexagon
vertexFn(_1) {
  float time = uni.iTime;
  time = mod(time,10.0);
  
  float hexrad = animation(kbuff, 0.0,1.0,time) - animation(kbuff, 8.0,9.0,time);
  hexrad = 0.1 * hexrad + 0.1;

  VertexOut v;
  float3 a = polygon(vid, 6, hexrad, uni.iResolution / uni.iResolution.x );
  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};
  v.color = {0.4 , 0.5, 0.6, 1};
  return v;
}

static float2 polar(float a) { return float2(cos(a),sin(a)); }

// circle
vertexFn(_2) {
  VertexOut v;
  float3 a = polygon(vid, 50, 0.075, uni.iResolution / uni.iResolution.x );
  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};

  v.color = {1, 0, 0, 1};
  // now I have the polygon.
  // position it based on instance.
  float time = uni.iTime;
  time = mod(time,10.0);

  float2 hex0 = polar((1.0 * pi) / 6.0) * uni.iResolution.x / uni.iResolution;
  float2 hex1 = polar((3.0 * pi) / 6.0) * uni.iResolution.x / uni.iResolution;
  float2 hex2 = polar((5.0 * pi) / 6.0) * uni.iResolution.x / uni.iResolution;
  float2 dirs[6];
  dirs[0] = hex0;
  dirs[1] = hex1;
  dirs[2] = hex2;
  dirs[3] = -hex0;
  dirs[4] = -hex1;
  dirs[5] = -hex2;

  float open = 1.2 + 0.2 * float( iid);
  float close = 6.0 + 0.2 * float( iid);
  float coff = 0.35 * (animation(kbuff, open,open+0.2,time) - animation(kbuff, close,close+0.2,time));
  
  v.where.xy += dirs[5 - iid] * coff;

  float2 aspect = uni.iResolution / uni.iResolution.x;
  v.where.xy = v.where.xy * aspect * rot2d( - animation(kbuff, 3.0,6.0,time)*TAU) / aspect;

  
  return v;
}
