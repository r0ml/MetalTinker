
#define shaderName lumidots

#include "Common.h" 
struct InputBuffer {
  bool COLORED = true;
};

initialize() {
}

fragmentFunc(texture2d<float> tex, constant InputBuffer & in) {
  float2 center = floor(thisVertex.where.xy/16.0)*16.0 + 8.0;
  float3 col = tex.sample(iChannel0, center * scn_frame.inverseResolution).rgb;
  float l = max(0.1, dot(col, float3(0.2125, 0.7154, 0.0721)));
  float dist = distance(center,thisVertex.where.xy)/8.0;
  float alpha = smoothstep(1.0, 0.5, dist/l);
  if (in.COLORED) {
    return float4(col.rgb * alpha, 1);
  } else {
    return float4(alpha, alpha, alpha, 1);
  }
}
