
#define shaderName Contour

#include "Common.h"

static float4 FakeStencil(float2 pos, float time, float2 mouse) {
  float shape = 1. - smoothstep(.13,.16,distance(pos,float2(0.5)));
  float t = time;
  shape = max(shape,1. - smoothstep(.05,.09,distance(pos,float2(cos(t)*1.1,sin(t)*.8) * .15 + float2(.5))));
  shape = max(shape, 1. - smoothstep(.025,.04,distance(pos,mouse)));
  return float4(1.) * shape;
}

fragmentFn() {
  float P = 0.001;
  float4 outlineColor = float4(.9,.15,0.04,1.);
  float2 uv = textureCoord;
  uv.y = (uv.y - 0.5) * uni.iResolution.y / uni.iResolution.x + 0.5;
  
  float stencil = FakeStencil(uv + float2(-1.,0.) * P, uni.iTime, uni.iMouse).x;
  stencil += FakeStencil(uv + float2(1.,0.) * P , uni.iTime, uni.iMouse).x;
  stencil += FakeStencil(uv + float2(0.,-1.) * P, uni.iTime, uni.iMouse).x;
  stencil += FakeStencil(uv + float2(0.,1.) * P , uni.iTime, uni.iMouse).x;
  
  stencil += FakeStencil(uv + float2(-.7,-.7) * P, uni.iTime, uni.iMouse).x;
  stencil += FakeStencil(uv + float2(.7,.7) * P  , uni.iTime, uni.iMouse).x;
  stencil += FakeStencil(uv + float2(.7,-.7) * P , uni.iTime, uni.iMouse).x;
  stencil += FakeStencil(uv + float2(-.7,.7) * P , uni.iTime, uni.iMouse).x;
  
  // Contour
  float a = smoothstep(3.5,4.5,stencil)*(1. - smoothstep(7.9,8.,stencil));
  
  // Stripes
  a += step(8.,stencil) * .2 * step(.7,sin((uv.x * 240. + uv.y *60.)+ uni.iTime * 7.)*.4+.6);
  
  float4 col = outlineColor * a;
  
  return col;
}


