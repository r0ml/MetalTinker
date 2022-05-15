
#define shaderName motion_blur

#include "Common.h" 

struct InputBuffer {
  bool blur = true;
  float3 speed;
};

initialize() {
  in.speed = { 1.1, 10, 20 };
}

static float2 p(float t) { return float2(sin(t),cos(t)/2.); }

fragmentFunc(device InputBuffer &in) {
  float4 c1 = float4(1, 1, 1, 1);
  float4 c2 = float4(0, 0.13, 0, 1);
  float aa = 4;
  float samples = 0.6;

  float time = scn_frame.time * in.speed.y;
  
  float2 uv = worldCoordAdjusted;
  
  float4 fragColor=c2;
  float2 reso = 1 / scn_frame.inverseResolution;

  if (in.blur) {
    for(float i = 1 - in.speed.y * 5 * samples; i < in.speed.y * 5 * samples; i++) {
      float2 c=p(time-i/350./samples);
      float d=distance(c,uv);
      if (d < 0.1) {
        fragColor = mix(c1,c2,abs(i)/(in.speed.y * 4.5 *samples)/1.1);
        if (i>0) break;
      }
    }
  } else {
    fragColor = mix(c2,c1,smoothstep(0.1, 0.1 - aa/reso.y, distance(p(time),uv)));
  }
  return fragColor;
}
