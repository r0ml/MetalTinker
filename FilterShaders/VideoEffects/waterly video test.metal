/** 
 Author: FabriceNeyret2
 distort a texture with noise
 */

#define shaderName waterly_video_test

#include "Common.h" 

struct InputBuffer {
};

initialize() {
//    setTex(0, asset::lava);
//  setTex(1, asset::amelia_earhart);
}

 



constant const float SCALE = 1.;

// --- noise functions from https://www.shadertoy.com/view/XslGRr
// Created by inigo quilez - iq/2013

constant const float3x3 m = float3x3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );

/*static float fbm( float3 p )
{
  float f;
  f  = 0.5000*noisePerlin( p ); p = m*p*2.02;
  f += 0.2500*noisePerlin( p ); p = m*p*2.03;
  f += 0.1250*noisePerlin( p ); p = m*p*2.01;
  f += 0.0625*noisePerlin( p );
  return f;
}*/
// --- End of: Created by inigo quilez --------------------
static float mynoise ( float3 p)
{
  return noisePerlin(p);
  //return .5+.5*sin(50.*noise(p));
}
static float myfbm( float3 p )
{
  float f;
  f  = 0.5000*mynoise( p ); p = m*p*2.02;
  f += 0.2500*mynoise( p ); p = m*p*2.03;
  f += 0.1250*mynoise( p ); p = m*p*2.01;
  f += 0.0625*mynoise( p ); p = m*p*2.05;
  f += 0.0625/2.*mynoise( p ); p = m*p*2.02;
  f += 0.0625/4.*mynoise( p );
  return f;
}
/*static float myfbm2( float3 p )
{
  float f;
  f  = 1. - 0.5000*mynoise( p ); p = m*p*2.02;
  f *= 1. - 0.2500*mynoise( p ); p = m*p*2.03;
  f *= 1. - 0.1250*mynoise( p ); p = m*p*2.01;
  f *= 1. - 0.0625*mynoise( p ); p = m*p*2.05;
  f *= 1. - 0.0625/2.*mynoise( p ); p = m*p*2.02;
  f *= 1. - 0.0625/4.*mynoise( p );
  return f;
}*/

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord;
  float3 v;
  float3 p = 4.*float3(uv,0.)+uni.iTime*1.2; // (.1,.7,1.2);
  float x = myfbm(p);
  //v = float3(x);
  v = (.5+.5*sin(x*float3(30.,20.,10.)*SCALE))/SCALE;
  float g = 1.;
  //g = pow(length(v),1.);
  //g =  .5*noise(8.*m*m*m*p)+.5; g = 2.*pow(g,3.);
  v *= g;
  float3 Ti = tex0.sample(iChannel0,.02*v.xy+uv).rgb*1.4-.2;
  float3 Tf = tex1.sample(iChannel0,.02*v.xy+uv).rgb;
  float3 T=Ti;
  // T = Ti+(1.-Ti)*Tf; 
  float3 T1,T2;
  T1 = float3(0.,0.,1.); T1 *= .5*(T+1.);
  T2 = float3(1.,1.,1.); //T2 = 1.2*Ti*float3(1.,.8,.6)-.2;
  v = mix(mix(T1,1.*Tf,.5),T2,T);
  return float4(v,1.0);
  
}

