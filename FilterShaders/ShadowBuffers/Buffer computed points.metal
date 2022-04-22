
// FIXME: the colors are wrong

#define shaderName Buffer_computed_points

#include "Common.h"

struct KBuffer {  };
initialize() {}


fragmentFn1() {
  FragmentOutput f;
  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  uv.y = 1 - uv.y;
  
  uv.x -= .5;
  uv.x *= uni.iResolution.x / uni.iResolution.y;
  uv.x += .5;
  
  f.fragColor *= 0.;
  
  for (int y = 0; y < 128; y++) {
    float4 c = renderInput[0].read(uint2(0, y));
    f.fragColor = mix(f.fragColor, abs(c.xyzx), smoothstep(0., 1., 1. / length(uv - c.xy) * .015));
  }

// =========================================================================

  
  float4 fragColor = float4(-.5);
  
  if ( thisVertex.where.x < 1 && thisVertex.where.y < 128) {
    
    if (uni.iFrame < 2) {
      
      // initial position
      f.pass1.x = 0.5;
      f.pass1.y = rand( thisVertex.where.yx / uni.iResolution ) / 2. -.5;
      
      float2 winCoord = thisVertex.where.xy;
      // initial speed vector
      f.pass1.z = rand(winCoord * fragColor.xy);
      f.pass1.w = rand(fragColor.xy * 1000.+ uni.iDate.w * 100.);
      
      
    } else {
      f.pass1 = renderInput[0].read(uint2(thisVertex.where.xy)) - .5;
      
      f.pass1.w -= .2;
      
      if (abs(f.pass1.x) > .5) {
        f.pass1.z = -f.pass1.z;
      }
      
      if (f.pass1.y < -.5) {
        f.pass1.w = -f.pass1.w;
      }
      
      if (f.pass1.y > .5) {
        f.pass1.w = -0.1;
      }
      
      f.pass1.xy += (f.pass1.zw) * 0.01;
      
      f.pass1 += .5;
    }
    
  }
  
  return f;
  
}

