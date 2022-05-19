
#define shaderName rotoscoping

#include "Common.h" 

struct InputBuffer {
  bool ENABLE_COLOR = true;
  bool ENABLE_QUANTIZATION = true;
};

initialize() {
}


// The layers

constant const float QUANTIZATION_FULL =  6.;
// constant const float QUANTIZATION_LOW = 1.2;

static float3 texsample(float2 uv, float mul, texture2d<float> vid0)
{
  return vid0.sample(iChannel0, uv).xyz * mul;
}

static float3 denoise(thread float2& uv, float mul, texture2d<float> vid0)
{
  const float rads = 256., val1 = .125;
  float dx, dy;
  
  float3 acc = float3(0);
  
  for (int i = 1; i < 16; ++i)
  {
    dx = dy = 1. / rads;
    acc += texsample(uv + float2(-dx, -dy), mul, vid0) * val1;
    acc += texsample(uv + float2( 0., -dy), mul, vid0) * val1;
    acc += texsample(uv + float2(-dx,  0.), mul, vid0) * val1;
    acc += texsample(uv + float2( dx,  0.), mul, vid0) * val1;
    acc += texsample(uv + float2( 0.,  dy), mul, vid0) * val1;
    acc += texsample(uv + float2( dx,  dy), mul, vid0) * val1;
    acc += texsample(uv + float2(-dx,  dy), mul, vid0) * val1;
    acc += texsample(uv + float2( dx, -dy), mul, vid0) * val1;
  }
  
  return acc / 16.;
}

static float3 rotoscope_full(float2 uv, texture2d<float> vid0)
{
  float3 cl = denoise(uv, 3.5, vid0) / QUANTIZATION_FULL;
  
  // Quantize
  float3 rc = float3(0);
  float lm = luminance(cl);
  for (int l = 1; l <= int(QUANTIZATION_FULL); ++l) {
    float coef = 1. / float(l);
    if (lm > coef){
      rc += coef;
    }
  }
  
  return rc;
}

/*

 static float3 rotoscope_low(float2 uv, texture2d<float> vid0)
 {
 float3 cl = denoise(uv, 3.5, vid0) / QUANTIZATION_LOW;

 // Quantize
 float3 rc = float3(0);
 float lm = luminance(cl);
 for (int l = 1; l <= int(QUANTIZATION_LOW); ++l) {
 float coef = 1. / float(l);
 if (lm > coef){
 rc += coef;
 }
 }

 return rc;
 }
 */

/*
 static float edge(float2 uv, texture2d<float> vid0)
 {
 const float d = 1. / 768.;

 float3 hc =rotoscope_low(uv + float2(-d,-d), vid0)
 *  1. + rotoscope_low(uv + float2( 0,-d), vid0) *  2.
 +rotoscope_low(uv + float2( d,-d), vid0) *  1.
 + rotoscope_low(uv + float2(-d, d), vid0) * -1.
 +rotoscope_low(uv + float2( 0, d), vid0) * -2.
 + rotoscope_low(uv + float2( d, d), vid0) * -1.;

 float3 vc =rotoscope_low(uv + float2(-d,-d), vid0) *  1.
 + rotoscope_low(uv + float2(-d, 0), vid0) *  2.
 +rotoscope_low(uv + float2(-d, d), vid0) *  1.
 + rotoscope_low(uv + float2( d,-d), vid0) * -1.
 +rotoscope_low(uv + float2( d, 0), vid0) * -2.
 + rotoscope_low(uv + float2( d, d), vid0) * -1.;

 return luminance(vc*vc + hc*hc);
 }
 */

fragmentFunc(texture2d<float> tex, constant InputBuffer &in, constant float2& mouse) {
  float2 uv = textureCoord;
  float3 ns = texsample(uv, 1., tex);
  
  float3 cl = in.ENABLE_QUANTIZATION ?  rotoscope_full(uv, tex) : 1;
  float m = mouse.x ;
  
  if (in.ENABLE_COLOR) {
    cl *= ns;
  }
  
  float3  frs = float3(
                       (uv.x  < m ? ns : cl)    // Mix the 2 channels
                       * smoothstep(0., scn_frame.inverseResolution.y, abs(m - uv.x))
                       );
  
  return float4(frs, 1);
}
