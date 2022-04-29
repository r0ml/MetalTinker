
#define shaderName Buffer_computed_points
#define SHADOWS 2

#include "Common.h"


struct Buffer {
  float clem[128];
};

fragmentFn(device struct Buffer &velo) {
  FragmentOutput f;

  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
//  uv.y = 1 - uv.y;
  
  uv.x -= .5;
  uv.x *= uni.iResolution.x / uni.iResolution.y;
  uv.x += .5;
  
  f.color0 = 0.;
  
  for (int y = 0; y < 128; y++) {
    float4 c = lastFrame[1].read(uint2(0, y));
    f.color0 = mix(f.color0, abs(c.xyzx), smoothstep(0., 1., 1. / length(uv - c.xy) * .015));
  }

// =========================================================================

  
  float4 fragColor = float4(-.5);
  
  if ( thisVertex.where.x < 1 && thisVertex.where.y < 128) {
    
    if (uni.iFrame < 2) {
      
      // initial position
      f.color1.x = 0.5;
      f.color1.y = rand( thisVertex.where.yx / uni.iResolution ) / 2. -.5;
      
      float2 winCoord = thisVertex.where.xy;
      // initial speed vector
      f.color1.z = rand(winCoord * fragColor.xy);
      f.color1.w = rand(fragColor.xy * 1000.+ uni.iTime * 100.);
      
      
    } else {
      f.color1 = lastFrame[1].read(uint2(thisVertex.where.xy)) - .5;
      
      f.color1.w -= .2;
      
      if (abs(f.color1.x) > .5) {
        f.color1.z = -f.color1.z;
      }
      
      if (f.color1.y < -.5) {
        f.color1.w = -f.color1.w;
      }
      
      if (f.color1.y > .5) {
        f.color1.w = -0.1;
      }
      
      f.color1.xy += (f.color1.zw) * 0.01;
      
      f.color1 += .5;
    }
    
  }
  
  return f;
  
}

