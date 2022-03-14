
#define shaderName shutter_007

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float2  U = worldCoordAspectAdjusted;
  
  float4 fragColor = tex.sample(iChannel0,.5+.5*U);
  
  float N = 12., c = cos(TAU/N),s=sin(TAU/N),
  a = PI/4.*(.5+.5*sin(uni.iTime)),d,A;
  
  for (int i=0; i<20; i++) {
    d = -dot(U-float2(-1,1),float2(sin(a),cos(a)));
    A = smoothstep(.01,0.,d);
    fragColor.rgb += (1.-fragColor.w) * A * float3(1.-4.*smoothstep(.01,0.,abs(d)));
    fragColor.w = A;
    U *= float2x2(c,-s,s,c);
  }
  fragColor *= smoothstep(1.,.99,length(U));
  fragColor.w = 1;
  return fragColor;
}

