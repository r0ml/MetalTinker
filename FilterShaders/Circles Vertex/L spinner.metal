
#define shaderName l_spinner

#include "Common.h" 

fragmentFn() {
  float2 uv = textureCoord * aspectRatio;
  
  float2 p = uv - float2(.87,.5);
  float time = uni.iTime * 1.5;
  
  float angle = -(time - sin(time + PI) * cos(time )) - time *.95;
  float2x2 rot = float2x2(cos(angle),sin(angle),-sin(angle),cos(angle));
  p = rot * p;
  
  float3 col = float3(0.);
  float L = length(p);
  float f = 0.;
  
  f = smoothstep(L-.005, L, .35);
  f -= smoothstep(L,L + 0.005, .27);
  //f = step(sin(L * 200. + uni.iTime * p.x)*.5+.5,.25); // uncomment for a headache
  
  float t = mod(time,TAU) - PI;
  float t1 = -PI ;
  float t2 = sin(t) *  (PI - .25) ;
  
  float a = atan2(p.y,p.x)  ;
  f = f * step(a,t2) * (1.-step(a,t1)) ;
  
  
  col = mix(col,float3(cos(time),cos(time + TAU / 3.),cos(time + 2.* TAU/3.)),f);
  
  return float4(col,1.0);
}
