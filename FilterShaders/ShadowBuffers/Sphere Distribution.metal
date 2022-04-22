
#define shaderName Sphere_Distribution
#define SHADOWS 2

#include "Common.h"


// some numbers I found by experimentation
// Pretty good pattern - covers a lot of directions in early cycles,
// then fills in gaps, with a bit of a pattern (lower digits affect the pattern)
//    float sina = (float((seed*0x73493U)&0xfffffU)/float(0x100000))*2. - 1.;
//    float b = TAU*(float((seed*0xAF71FU)&0xfffffU)/float(0x100000));
// AAARGH! It has huge gaps at the poles!
// tweaked it a tiny amount and got something far better
static float3 SphereRand( uint seed ) {
  float sina = (float((seed*0x73494U)&0xfffffU)/float(0x100000))*2. - 1.;
  float b = TAU*(float((seed*0xAF71FU)&0xfffffU)/float(0x100000));
  float cosa = sqrt(1.-sina*sina);
  return float3(cosa*cos(b),sina,cosa*sin(b));
}


fragmentFn() {
  FragmentOutput fff;

  float4 c = lastFrame[1].read(uint2(thisVertex.where.xy));
  c = 1 - c/(1.+sqrt(c.a/80.));
  c.w = 1;
  // ============================================== buffers =============================

  if ( uni.iFrame == 0 ) fff.color1 = float4(0);
  else fff.color1 = lastFrame[1].read(uint2(thisVertex.where.xy));
  
  float2 uv = (thisVertex.where.xy*2.-uni.iResolution.xy)/uni.iResolution.y;

  const float zoom = 1.;
  //const float zoom = 8.; uv.x -= 7.;

  float2 projection = normalize(float2(1,.2));

  const uint n = 1000U; // number to add per frame
  for ( uint i=0U; i < n; i++ )
  {
    float3 r = SphereRand(uint(uni.iFrame)*n+i);

    // tilt the sphere
    //r.yz = r.yz*sqrt(.75) + r.zy*float2(1,-1)*sqrt(.25);

    // hide back face - actually don't do this, because when I fire rays in a hemisphere I mirror them in a plane
    //if ( r.y < .0 ) continue;

    // zoom
    r *= zoom;

    float s = smoothstep(0.,.004,length(float2(r.x,dot(r.yz,projection.yx*float2(-1,1)))/**4./(dot(r.yz,projection+5.)*/-uv));
    //fff.pass1 *= s;
    fff.color1 += 1.-s;
  }

  fff.color1.a = uni.iTime*float(n)/(zoom*zoom);
  fff.color0 = c;
  return fff;
}
