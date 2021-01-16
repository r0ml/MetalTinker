
#define shaderName rotating_color_ring

#include "Common.h" 

struct InputBuffer {
  bool IQ = true;
};

initialize() {
}



//You could say it's speed
#define LOOP_TIME 20.0
//No i couldn't think of a more unique name
#define LOOPS 0.5

//Circle constants
constant const float r1 = 0.25;
constant const float r2 = 0.48;
//PI constants
constant const float PI_HALF = PI / 2.0;

constant const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

static float3 hue2rgb(float hue){
  float3 p = abs(fract(hue + K.xyz) * 6.0 - K.www);
  return saturate(p - K.xxx);
}

static float getRingMult(float2 va){
  return smoothstep(r1, r2, length(va));
}

static float3 getBackground(){
  return float3(0.2);
}

static float2 getStartVec(float time){
  float angle = (time/LOOP_TIME) * TAU;
  return float2(cos(angle), sin(angle));
}

static float3 genColor(float2 vKA, float time, InputBuffer in){
  float angle;
  if (in.IQ) {
    angle = (time/LOOP_TIME) * TAU + atan2(vKA.x, vKA.y) - PI_HALF;
  } else {
    angle = dot(getStartVec(time), normalize(vKA));
    angle = acos(angle);
  }
  return hue2rgb(angle / PI * LOOPS);
}

fragmentFn() {
  float2 pA = worldCoordAspectAdjusted / 2;
  float dist = getRingMult(pA);
  float3 final = getBackground();
  if(dist!=0.0 && dist!=1.0){
    final = mix(genColor(pA, uni.iTime, in), final, dist);
  }
  return float4(gammaDecode(final), 1.0);
}

