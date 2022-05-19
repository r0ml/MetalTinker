
#define shaderName Sketchy_Stippling_Stylization

#include "Common.h"

struct InputBuffer {
  bool compare;
};

initialize() {
  in.compare = true;
}

static constant int mSize = 9;

constant const int kSize = (mSize-1)/2;
constant const float sigma = 3.0;

// Gaussian PDF
static float normpdf(const float x, const float sigma)
{
  return 0.39894 * exp(-0.5 * x * x / (sigma * sigma)) / sigma;
}

// 
static float3 colorDodge(const float3 src, const float3 dst)
{
  return step(0.0, dst) * mix(min(float3(1.0), dst/ (1.0 - src)), float3(1.0), step(1.0, src));
}

static float greyScale(const float3 col)
{
  return dot(col, float3(0.3, 0.59, 0.11));
  //return dot(col, float3(0.2126, 0.7152, 0.0722)); //sRGB
}

static float2 random(float2 p){
  p = fract(p * (float2(314.159, 314.265)));
  p += dot(p, p.yx + 17.17);
  return fract((p.xx + p.yx) * p.xy);
}

fragmentFunc(texture2d<float> tex, device InputBuffer& in) {
  float kernelx[mSize];
  float2 q = textureCoord;
  float3 col = tex.sample(iChannel0, q).rgb;

  float2 r = random(q);
  r.x *= TAU;
  float2 cr = float2(sin(r.x),cos(r.x))*sqrt(r.y);

  float3 blurred = tex.sample(iChannel0, q + cr * (float2(mSize) * scn_frame.inverseResolution) ).rgb;

  // comparison
  if (in.compare) {
    blurred = float3(0.0);
    float Z = 0.0;
    for (int j = 0; j <= kSize; ++j) {
      kernelx[kSize+j] = kernelx[kSize-j] = normpdf(float(j), sigma);
    }
    for (int j = 0; j < mSize; ++j) {
      Z += kernelx[j];
    }

    // this can be done in two passes
    for (int i = -kSize; i <= kSize; ++i) {
      for (int j = -kSize; j <= kSize; ++j) {
        blurred += kernelx[kSize+j]*kernelx[kSize+i]*tex.sample(iChannel0, (thisVertex.where.xy+float2(float(i),float(j))) * scn_frame.inverseResolution).rgb;
      }
    }
    blurred = blurred / Z / Z;

    // an interesting ink effect
    //r = random2(q);
    //float2 cr = float2(sin(r.x),cos(r.x))*sqrt(-2.0*r.y);
    //blurred = texture(iChannel0, q + cr * (float2(mSize) / uni.iResolution.xy) ).rgb;
  }

  float3 inv = float3(1.0) - blurred;
  // color dodge
  float3 lighten = colorDodge(col, inv);
  // grey scale
  float3 res = float3(greyScale(lighten));

  // more contrast
  res = float3(pow(res.x, 3.0));
  //res = saturate(res * 0.7 + 0.3 * res * res * 1.2);

  // edge effect
  if (in.compare)
    res *= 0.25 + 0.75 * pow( 16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.15 );
  return float4(res, 1.0);
}
