
#define shaderName Animation_Test
#define PASSES 2

#include "Common.h"

struct InputBuffer {
  struct {
    int OverShoot;
    int Spring;
    int Bounce;
    int Quart;
    int Linear;
    int QuartSine;
    int HalfSine;
  } animation;
  struct {
    int4 _2;
    int4 _1;
  } pipeline;
};

initialize() {
  in.animation.Quart = 1;

//  in.pipeline._1 = {3, 18, 1, 0};
//  in.pipeline._2 = {3, 150, 6, 0};
}

frameInitialize() {
  ctrl.pass[1].vertexCount = 18;
  ctrl.pass[1].instanceCount = 1;

  ctrl.pass[0].vertexCount = 150;
  ctrl.pass[0].instanceCount = 6;
}

//--- Animation Functions ---
static float animation(InputBuffer in, float s, float e, float t) {
  if (in.animation.OverShoot) {
    return smoothstep(s,e,t) + sin(smoothstep(s,e,t)*pi) * 0.5;
  } else if (in.animation.Spring) {
    t = saturate((t - s) / (e - s) );
    return 1.0 - cos(t*pi*6.0) * exp(-t*6.5);
  } else if (in.animation.Bounce) {
    t = saturate((t - s) / (e - s) );
    return 1.0 - abs(cos(t*pi*4.0)) * exp(-t*6.0);
  } else if (in.animation.Quart) {
    t = saturate((t - s) / (e - s) );
    return 1.0-pow(1.0 - t,4.0);
  } else if (in.animation.Linear) {
    t = saturate((t - s) / (e - s) );
    return t;
  } else if (in.animation.QuartSine) {
    t = saturate((t - s) / (e - s) );
    return sin(t * pi/2.0);
  } else if (in.animation.HalfSine) {
    t = saturate((t - s) / (e - s) );
    return 1.0 - cos(t * pi)*0.5+0.5;
  }
  // should never get here
  return 0;
}

static float2 polar(float a) { return float2(cos(a),sin(a)); }

// circle
vertexPass(_1) {
  VertexOut v;
  v.where.xy = polygon(vid, 50, 0.075 );
  v.where.zw = {0, 1};
  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

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
  float coff = 0.35 * (animation(in, open,open+0.2,time) - animation(in, close,close+0.2,time));
  
  v.where.xy += dirs[5 - iid] * coff;
  
  float2 aspect = uni.iResolution / uni.iResolution.x;
  v.where.xy = v.where.xy * aspect * rot2d( - animation(in, 3.0,6.0,time)*TAU) / aspect;
  
  
  return v;
}

// hexagon
vertexPass(_2) {
  float time = uni.iTime;
  time = mod(time,10.0);

  float hexrad = animation(in, 0.0,1.0,time) - animation(in, 8.0,9.0,time);
  hexrad = 0.1 * hexrad + 0.1;

  VertexOut v;
  v.where.xy = polygon(vid, 6, hexrad );
  v.where.zw = {0, 1};
  v.where = v.where * scale(aspectRatio.y, aspectRatio.x, 1);

  v.color = {0.4 , 0.5, 0.6, 1};
  return v;
}
