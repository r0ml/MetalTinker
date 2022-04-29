
#define shaderName Belousov_Zhabotinsky_Reaction

#include "Common.h" 

struct InputBuffer {
  float3 timestep;
};

initialize() {
  in.timestep = {0.001, 0.01, 0.05};
}

fragmentFn( texture2d<float> lastFrame ) {

#define T(d) n += lastFrame.sample(iChannel0, fract(vUv+d)).xyz;
  
  float2 vUv = thisVertex.where.xy / uni.iResolution.xy;
  float4 t = float4(1. / uni.iResolution.xy, -1. / uni.iResolution.y, 0.0);
  float3 p = lastFrame.sample(iChannel0, vUv).xyz;
  float3 n = float3(0);
  
  // shorthand for summing the values over all 8 neighbors
  T(t.wy) T(t.xy) T(t.xw) T(t.xz) T(t.wz) T(-t.xy) T(-t.xw) T(-t.xz)
  
  // this line encodes the rules
  float3 result = p + in.timestep.y * float3(n.z - n.y, n.x - n.z, n.y - n.x);
  
  if(uni.iFrame == 0 || uni.wasMouseButtons) {
    // initialize with noise
    return float4(rand3(thisVertex.where.xy), 1);
  } else {
    return float4(saturate(result), 1);
  }
}

