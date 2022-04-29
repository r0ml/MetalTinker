
#define shaderName multi_pass_motion_blur_2

#include "Common.h" 

struct KBuffer {
  struct {
    struct {
      int _2;
      int _4;
      int _5;
    } variant;
  } options;
};
initialize() {}


fragmentFn1() {
  FragmentOutput f;

  if (kbuff.options.variant._2) {
    f.fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy / uni.iResolution);
    //f = 1.-smoothstep(f,f+0.01, float4(1));

    float2 uv = (2. * thisVertex.where.xy - uni.iResolution)/uni.iResolution.y*2.;
    float t = uni.iTime*0.5;
    float r = (sin(t*5.)+.7);
    // paths
    float2 d0 = float2(cos(t), sin(t)) * r;
    float2 d1 = float2(cos(t+1.57), sin(t+1.57)) * r; // +90Â°

    // metaballs
    float m0 = 0.02/dot(uv-d0,uv-d0);
    float m1 = 0.02/dot(uv+d0,uv+d0);
    float m2 = 0.02/dot(uv-d1,uv-d1);
    float m3 = 0.02/dot(uv+d1,uv+d1);

    // current color
    float4 col = float4(float3(m0+m1+m2+m3),1);

    // last color
    float4 bufA = renderInput[0].sample(iChannel0, thisVertex.where.xy / uni.iResolution*0.995);

    // simple blending of new and last color
    f.pass1 = col * 0.2 + bufA * 0.8;

    // add some colored aura to the metaballs
    f.pass1 += smoothstep(bufA, bufA+0.01, float4(.8,.2,.5,1))*0.01;
    return f;
  } else if (kbuff.options.variant._4) {
    f.fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy / uni.iResolution.xy);
    f.pass1 = float4(.8,.2,.5,1);
    float2 s = uni.iResolution.xy;
    float4 h = renderInput[0].sample(iChannel0, thisVertex.where.xy / s);
    float2 g = (thisVertex.where.xy+thisVertex.where.xy-s)/s.y*1.3;
    float2
    k = float2(1.6,0) + mod(uni.iDate.w,TAU),
    a = g - sin(k),
    b = g - sin(2.09 + k),
    c = g - sin(4.18 + k);
    f.pass1 = (0.2/max(abs(a.x)+a.y,-a.y) // tri
               + 0.2/max(abs(b.x), abs(b.y)) // quad
               + 0.2/max(max(abs(c.y - c.x), abs(c.y + c.x)), abs(c.x))) // losange
    * 0.04 + h * 0.95 + step(h, f.pass1) * 0.05;
    return f;
  } else if (kbuff.options.variant._5) {
    f.fragColor = renderInput[0].sample(iChannel0, thisVertex.where.xy / uni.iResolution.xy);
    f.pass1 = float4(.8,.2,.5,1);
    float4 h = renderInput[0].sample(iChannel0, thisVertex.where.xy / uni.iResolution * 0.995); // the magie is the 0.995 of s
    float2 g = (thisVertex.where.xy+thisVertex.where.xy-uni.iResolution)/uni.iResolution.y*1.3;
    float2 k = float2(1.6,0) + uni.iDate.w,a;
    float m  = 0;
    for (float i=0.;i<5.;i++) {
      a = g - sin(k + 1.25*i);
      m += 0.02/dot(a,a);
    }

    f.pass1 = m * 0.03 + h * 0.97 + step(h, f.pass1) * 0.01;
    return f;
  } else {
    discard_fragment();
  }
}
