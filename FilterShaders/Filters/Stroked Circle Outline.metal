
#define shaderName stroked_circle_outline

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

constant const float ringWidth = 0.45;
constant const float3 ringColor = float3(1.0,0.2,0.7);

static float4 outline(float width, float2 tc, float3 color, float2 reso, texture2d<float> tex){
  float4 t = tex.sample(iChannel0, tc);
  tc -= 0.5;
  tc.x *= reso.x / reso.y;
  
  float grad = length(tc);
  float circle = smoothstep(0.5, 0.49, grad);
  float ring = circle - smoothstep(width, width-0.005, grad);
  
  t = (t * (circle - ring));
  t.rgb += (ring * color);
  
  return t;
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  return outline(ringWidth, uv, ringColor, uni.iResolution, tex);
}
