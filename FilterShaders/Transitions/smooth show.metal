
#define shaderName smooth_show

#include "Common.h" 

struct InputBuffer {
  float3 speed;
  float3 dp;
};

initialize() {
  in.dp = {0, 0.2, 0.5};
  in.speed = {0.1, 0.5, 2};
}

fragmentFunc(texture2d<float> tex, device InputBuffer& in) {
  float speed = scn_frame.time * in.speed.y;

  float2 uv = textureCoord;

  float op = smoothstep(max(1.-speed-in.dp.y,-in.dp.y),
                        max(1.-speed,0.),
                        1.-uv.y);

  return op * tex.sample(iChannel0,uv);
}


