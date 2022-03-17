
#define shaderName transition_burning

#include "Common.h" 
struct InputBuffer {
};

initialize() {
//  setTex(0, asset::flagstones);
//  setTex(1, asset::pebbles);
}

static float3 TextureSource(float2 uv, texture2d<float> tex0)
{
  return tex0.sample(iChannel0, uv).rgb;;
}

static float3 TextureTarget(float2 uv, texture2d<float> tex1)
{
  return tex1.sample(iChannel0, uv).rrr;
}

static float fbm(float2 p)
{
  float v = 0.0;
  v += noisePerlin(p)*.5;
  v += noisePerlin(p*2.)*.25;
  v += noisePerlin(p*4.)*.125;
  return v;
}

fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 uv = worldCoordAspectAdjusted / 2.;

  float3 src = TextureSource(uv, tex0);
  float3 tgt = TextureTarget(uv, tex1);

  float3 col = src;

  uv.x -= 1.5;

  float ctime = mod(uni.iTime*.5,2.5);

  // burn
  float d = uv.x+uv.y*0.5 + 0.5*fbm(uv*15.1) + ctime*1.3;
  if (d >0.35) col = saturate(col-(d-0.35)*10.);
  if (d >0.47) {
    if (d < 0.5 ) col += (d-0.4)*33.0*0.5*(0.0+noisePerlin(100.*uv+float2(-ctime*2.,0.)))*float3(1.5,0.5,0.0);
    else col += tgt; }

  return float4(col, 1);
}