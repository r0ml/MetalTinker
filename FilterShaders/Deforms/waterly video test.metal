
#define shaderName waterly_video_test

#include "Common.h" 

constant const float3x3 m = float3x3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );


static float mynoise ( float3 p) {
  return noisePerlin(p);
}

static float myfbm( float3 p ) {
  float f;
  f  = 0.5000*mynoise( p ); p = m*p*2.02;
  f += 0.2500*mynoise( p ); p = m*p*2.03;
  f += 0.1250*mynoise( p ); p = m*p*2.01;
  f += 0.0625*mynoise( p ); p = m*p*2.05;
  f += 0.0625/2.*mynoise( p ); p = m*p*2.02;
  f += 0.0625/4.*mynoise( p );
  return f;
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord;
  float3 p = 4.*float3(uv,0.)+uni.iTime*1.2; // (.1,.7,1.2);
  float x = myfbm(p);
  float3 v = .5+.5*sin(x*float3(30.,20.,10.));
  float3 Ti = tex0.sample(iChannel0, .02*v.xy+uv).rgb * 1.4 - .2;
  float3 Tf = tex1.sample(iChannel0, .02*v.xy+uv).rgb;
  v = mix(mix( float3(0, 0, 1), Tf, .5), 1, Ti);
  return float4(v,1.0);
}
