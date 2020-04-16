
#define shaderName Breathing_Ring

#include "Common.h" 

struct KBuffer {
  float4 clearColor;
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  // kbuff.clearColor = (float4(78, 58, 189, 255) / 255.) ;
  // kbuff.clearColor *= kbuff.clearColor;
  kbuff.clearColor = float4(24, 13, 140, 255)/255.;
  kbuff.pipeline._1 = {3, 600, 1, 0};
}

vertexFn(_1) {
  float radius = 0.25 + 0.025 + 0.25 * sin(uni.iTime);
  VertexOut v;
  float3 a = annulus(vid, 200, radius - 0.05, radius, uni.iResolution / uni.iResolution.x );
  v.barrio.xy = a.xy + 0.5;
  v.barrio.zw = { 0, 1};
  v.where.xy = (2 * v.barrio.xy - 1) * 0.5;
  v.where.zw = {0, 1};

  v.color = float4(255, 0, 231, 255) / 255.;
//   float2 ctr = abs(float2( mod(uni.iTime, 2 * (1 - radius) ) - (1 - radius), 0.6 * sin(uni.iTime*5.))) - 0.5 + radius / 2 ;
//   v.where.xy = v.where.xy + 2 * ctr;
  return v;
}



/*



float circleSDF(float radius, float2 pos) {
    return length(pos) - radius;
}

float sceneSDF(float2 pos) {
    float thickness = 0.1;
    float radius = 0.5 + 0.5*sin(uni.iTime);
    return abs(circleSDF(radius, pos)) - 0.5 * thickness;
}

void run()
    float4 bgColor = float4(0.32, 0.22, 0.77, 1.0);
    float4 sceneColor = float4(1.0, 0.0, 0.8, 1.0);
    float2 pos = (2.0 * thisVertex.where.xy - uni.iResolution.xy)/uni.iResolution.y;
    float dist = sceneSDF(pos);
    fragColor = mix(sceneColor, bgColor, 
                    smoothstep(0.0, 3.0/uni.iResolution.y, dist));
}


 */
