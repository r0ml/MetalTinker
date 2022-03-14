
#define shaderName Burning_Texture_Fade

#include "Common.h"
struct InputBuffer {
};

initialize() {
//  setTex(0, asset::flagstones);
//  setTex(1, asset::rust);
}

static float r(const float2 p)
{
  return fract(cos(p.x*42.98 + p.y*43.23) * 1127.53);
}


static float n(const float2 p)
{
  float2 fn = floor(p);
  float2 sn = smoothstep(float2(0), float2(1), fract(p));
  
  float h1 = mix(r(fn), r(fn + float2(1,0)), sn.x);
  float h2 = mix(r(fn + float2(0,1)), r(fn + float2(1)), sn.x);
  return mix(h1 ,h2, sn.y);
}

static float noise(const float2 p)
{
  return n(p/32.) * 0.58 +
  n(p/16.) * 0.2  +
  n(p/8.)  * 0.1  +
  n(p/4.)  * 0.05 +
  n(p/2.)  * 0.02 +
  n(p)     * 0.0125;
}

// smokey-hellish background
static float3 background(const float2 pos, float time, texture2d<float> tex)
{
  float2 offset = float2(0.0,0.01 * time);
  float3 color  = float3(1.0);
  
  for(int i = 0; i < 3; i++)
  {
    color += mix(tex.sample(iChannel0, pos - 0.25 * offset + 0.5),
                 tex.sample(iChannel0, pos - offset),
                 abs(mod(float(i) * 0.666, 2.0) - 1.0)).xyz * color * color;
  }
  
  return color * float3(.0666, .0266, .00333);
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = textureCoord * aspectRatio;
  
  float t = mod(uni.iTime*.15, 1.2);
  
  // fade to black
  float4 fragColor = mix(tex0.sample(iChannel0, uv), float4(0), smoothstep(t + .1, t - .1, noise(thisVertex.where.xy * .4)));
  
  // burning on the edges (when fragColor.a < .1)
  fragColor.rgb = saturate(fragColor.rgb + step(fragColor.a, .1) * 1.6 * noise(2000. * uv) * float3(1.2,.5,.0) );
  
  // fancy background under burned texture
  fragColor.rgb = fragColor.rgb * step(.01, fragColor.a) + background(.1 * uv, uni.iTime, tex1) * step(fragColor.a, .01);
  
  // alternatively
  //  if(fragColor.a < .01)
  //     fragColor = background(.1 * uv);
  
  // plain burn-to-black
  // fragColor.rgb *= step(.01, fragColor.a);
  return fragColor;
}
