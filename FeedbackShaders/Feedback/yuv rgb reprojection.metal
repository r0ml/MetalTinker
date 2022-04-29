/** 
 Author: pyBlob
 Left side shows YUV(0..1, -.6 .. +.6) -> RGB conversion and that most of the yuv-values produce invalid rgb-values.
 It renders slices of the RGB cube with constant Y sweeping back and forth.
 
 Right side is RGB -> YUV (low contrast, because not all used).
 */

#define shaderName yuv_rgb_reprojection

#import "Common.h"

struct KBuffer {
};
initialize() {}

 // SDTV with BT.601 tables
 // taken from https://en.wikipedia.org/wiki/YUV

 constant const float3x3 yuv = float3x3(
                 0.299, 0.587, 0.114,
                 -0.14713, -0.28886, 0.436,
                 0.615, -0.51499, -0.10001
                 );

 constant const float3x3 rgb = float3x3(
                 1, 0, 1.13983,
                 1, -0.39465, -0.58060,
                 1, 2.03211, 0
                 );

fragmentFn1() {
  FragmentOutput f;
  constexpr sampler chan(coord::normalized, address::clamp_to_edge, filter::nearest);
  
  f.fragColor = renderInput[0].sample(chan, thisVertex.where.xy/uni.iResolution.xy);
  f.fragColor.w = 1;

// ============================================== buffers =============================


  if (uni.iFrame < 3 ) {
    f.pass1 = 0;
    return f;
  }
  
  float2 uv = thisVertex.where.xy/uni.iResolution.xy;
  float2 uvx = uv;
  float time = sin(uni.iTime)*0.5+0.5;
  
  uv.x *= 2.;
  float3 col;
  
  if (uv.x < 1.)
  {
    col = float3(uv, time);
    col = col.zxy;
    col.yz -= .5;
    col.yz *= 1.2;
    col = col * rgb;
  }
  else
  {
    uv.x -= 1.;
    
    // float a = atan2(uv.y, uv.x);
    col = float3(uv, time);
    col = col * yuv;
    col.yz /= 1.2;
    col.yz += .5;
    col = col.yzx;
  }
  
  if ( any(col > 1) || any(col < 0) ) {
    col = mix(float3(0.5), renderInput[0].sample(chan, uvx).xyz, 0.999);
  }
  
  f.pass1 = float4(col, 1);
  
  return f;
}
