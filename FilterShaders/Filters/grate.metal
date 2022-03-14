
#define shaderName grate

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord * aspectRatio;
  
//  float2 uv = thisVertex.barrio.xy;
//  uv.x *= uni.iResolution.x / uni.iResolution.y;
  float tile = 200.0;
  float2 oo =  sin(uv*tile + float2(0.0,uni.iTime*10.0))*0.5 + 0.5;
  float doo = smoothstep(0.2, 0.8, 1.0 - dot(oo, float2(1.0)));
  
  return tex.sample(iChannel0, uv / aspectRatio)*doo;
}
