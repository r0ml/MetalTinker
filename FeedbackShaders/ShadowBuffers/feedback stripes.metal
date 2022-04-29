
#define shaderName feedback_stripes

#include "Common.h" 

struct KBuffer {
  float2 last_mouse;
};
initialize() {
}

computeFn() {
  if (uni.mouseButtons) {
    kbuff.last_mouse = uni.iMouse;
  }
}

float3 brightnessContrast(float3 value, float brightness, float contrast) {
  return (value - 0.5) * contrast + 0.5 + brightness;
}

fragmentFn2() {  FragmentOutput fff;
  float2 uv3 = thisVertex.where.xy/uni.iResolution.xy;

  float4 t = renderInput[1].sample(iChannel0, uv3)+0.03;
  //t.rgb = brightnessContrast(t.rgb, 0.0,2.0);
  //t = pow(t, float4(4.0));
  t = smoothstep(0.4, 0.7, t);
  //t = smoothstep(0.7, 0.9, t);
  //t = step(0.5, t);
  fff.fragColor = t;

  // ============================================== buffers =============================

  // just make a circle that you can move with the mouse

  float2 m = kbuff.last_mouse;
  m = m * 2.0 - 1.0;
  uv3.xy += -m.xy*0.5;
  float l = length(uv3 - 0.5 );
  float l1 = smoothstep(0.1, 0.11, l);
  l = 1.0 - l1;
  fff.pass1 = float4(l,l,l,1.0);

  // =============================================== buffer =================================

  float dampening = 0.9;
  float2 scale = float2(0.9);

  float2 uv = thisVertex.where.xy / uni.iResolution.xy;
  float2 uv2 = uv;

  m *= 0.5;

  // float aspect = uni.iResolution.y / uni.iResolution.x;

  //scale.x *= aspect;

  // scale tex coords based on buf a circle pos
  uv2 -= m;
  uv2 = 2.0 * uv2 - 1.0;
  uv2 *= scale;
  uv2 = 0.5 * uv2 + 0.5;
  uv2 += m;

  float4 a = renderInput[0].sample(iChannel0, uv);
  float4 b = renderInput[1].sample(iChannel0, uv2);

  b = a + (1.0 - b)*(dampening);//*(distance(uv-0.5, m)+1.0));
                                // b = fract(b);
  fff.pass2 = b;//clamp(b, float4(0.0), float4(1.0));
  fff.pass2.a = 1.0;

  return fff;
}
