
#define shaderName Arcs_2

#include "Common.h"

struct InputBuffer {};
initialize() {}

static float map(float3 p, float tim) {
  float R=3.;
  float d=abs(length(p.xy)-R)-.1;
  
  float msl=2.;
  float zi=floor((p.z)/msl);
  float a=atan2(p.y,p.x);
  float at=TAU*rand(zi)+tim*(rand(zi)-.5)*4.;
  float az=mod(at-a+TAU*.5,TAU)-TAU*.5;
  d=max(d,-abs(mod(p.z+.5*msl,msl)-msl*.5)+.2*msl);
  d=max(d,-max((abs(az)-rand(zi+.5)-.1)*R, abs(mod(p.z,msl)-.5*msl)-.4*msl));
  
  return d;
}

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  float3 ro=float3(uv,uni.iTime*2.),rd=normalize(float3(uv,1.)),mp=ro;
  int i;
  for (i=0;i<30;++i) {
    float md=map(mp, uni.iTime);
    if(md<.001)break;mp+=rd*md;
  }
  return float4(length(mp-ro)*.05);
}
