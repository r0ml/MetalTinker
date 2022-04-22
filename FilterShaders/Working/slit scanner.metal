
#define shaderName slit_scanner

#include "Common.h" 
struct KBuffer {
  int webcam;
};

initialize() {
}

fragmentFn1() {
  FragmentOutput f;
  const float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  float4 draw = renderInput[0].sample(iChannel0,uv);
  f.fragColor = float4(draw.rgb,1.);
  
  // ============================================== buffers =============================
  
  float3 colors = float3(0.);
  float scanline = (mod(uni.iTime / 10.0, 1.0));
  if ( scanline < uv.x + (2./uni.iResolution.x) && scanline > uv.x) {
    colors = webcam.sample(iChannel0,uv).rgb;
  } else {
    colors = draw.rgb;
  }
  f.pass1 = float4(colors,1.0);
  return f;
}
