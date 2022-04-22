/** 
 Author: yx
 ...
 */
#define shaderName Binary_1D_Cellular_Automata

#include "Common.h"

#define TEXT 1
#define NO_STROBE 1

#if TEXT

static float4 textx(float2 uv, int value)
{    
  uint font[16] =  {
    0xEAAAEu, // 0
    0x4644Eu, // 1
    0xE8E2Eu, // 2
    0xE8E8Eu, // 3
    0xAAE88u, // 4
    0xE2E8Eu, // 5
    0xE2EAEu, // 6
    0xE8888u, // 7
    0xEAEAEu, // 8
    0xEAE8Eu, // 9
    0xEAEAAu, // A
    0x6A6A6u, // B
    0xE222Eu, // C
    0x6AAA6u, // D
    0xE2E2Eu, // E
    0xE2E22u  // F
  };
  if (uv.x < 0. || uv.y < 0. || uv.x > 3. || uv.y > 5.)
    return float4(0);
  value = int(mod(float(value), 16.));
  return float4((font[value]>>int(uv.y*4.+uv.x-1.))&1u);
}
#endif

fragmentFn(texture2d<float> lastFrame) {
  FragmentOutput f;
  f.fragColor = renderInput[0].sample(iChannel0,thisVertex.where.xy/uni.iResolution.xy).rrrr;
  
#if NO_STROBE
  if (mod(float(uni.iFrame),uni.iResolution.y) < thisVertex.where.y)
  {
    f.fragColor = float4(.5);
  }
#endif
  
#if TEXT
  int rule = int(floor(float(uni.iFrame)/uni.iResolution.y));
  float2 textbox = thisVertex.where.xy - float2(0, uni.iResolution.y - 7.);
  
  if(textbox.y>=0. && textbox.x<13.)
  {
    f.fragColor = float4(0,0,0,0);
    f.fragColor += textx(textbox-float2(9,1), (rule/1)%10);
    f.fragColor += textx(textbox-float2(5,1), (rule/10)%10);
    f.fragColor += textx(textbox-float2(1,1), (rule/100)%10);
  }
#endif
  
  // ============================================== buffers =============================
  
  //int rule = 30;
  
  float2 uv = thisVertex.where.xy/uni.iResolution.xy;
  float2 o = 1./uni.iResolution.xy;
  
  if (thisVertex.where.y < 1.)
  {
    f.pass1.r = step(.5,rand(thisVertex.where.x));
  }
  else
  {
    float a = renderInput[0].sample(iChannel0,uv-float2( o.x,o.y)).r;
    float b = renderInput[0].sample(iChannel0,uv-float2(   0,o.y)).r;
    float c = renderInput[0].sample(iChannel0,uv-float2(-o.x,o.y)).r;
    int r = int(a*4.+b*2.+c);
    f.pass1.r = float((rule>>r)&1);
  }
  return f;
}
