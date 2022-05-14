
#define shaderName sunwave

#include "Common.h"

fragmentFunc() {
  float2 v = worldCoordAdjusted / 2;
  float t = fract((scn_frame.time * .07 + v.y)*17.);
  float3 a = float3( 1, .2, 0), b = -float3(.1, 0, .01);
  float4 fragColor = 0;
  fragColor.z = (v.y + 16.)*.0017;
  fragColor += v.y;
  fragColor.xyz += mix(length(v*0.7),pow(length(v*1.1) * .237,1.37),sin(scn_frame.time*.1)+1.);
  float q = step(t,1.3*v.y+.5) - length(v) * 3.;
  fragColor.xyz += mix(a,b,smoothstep(q,q+0.03,0.1));
  float2 st = 66.0 * v + float2(0,27);
  float aa = atan2(st.x,st.y) + PI;
  float r = PI*2./3.0;
  float d = cos(floor(.5+aa/r)*r-aa) * length(st);
  fragColor.gb += float2(1.0-smoothstep(.5,1.0,d*1.5))*1.5;
  fragColor.w = 1;
  return fragColor;
}
