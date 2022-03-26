
#define shaderName Blurs

#include "Common.h"
struct InputBuffer {
    struct {
      int cheap;
      int onepass;
      int grainy;
      int dfbox;
    } value;
};

initialize() {
}

fragmentFn(texture2d<float> tex) {

  float2 uv = textureCoord;
  if (in.value.cheap) {
    const uint ITERATIONS = 128;
    const float RADIUS = .3;
    float3 sum = tex.sample(iChannel0, uv).xyz;
  
    for(uint i = 0; i < ITERATIONS / 4; i++) {
      sum += tex.sample(iChannel0, uv + float2(float(i) / uni.iResolution.x, 0.) * RADIUS).xyz;
    }
  
    for(uint i = 0; i < ITERATIONS / 4; i++) {
      sum += tex.sample(iChannel0, uv - float2(float(i) / uni.iResolution.x, 0.) * RADIUS).xyz;
    }
  
    for(uint i = 0; i < ITERATIONS / 4; i++) {
      sum += tex.sample(iChannel0, uv + float2(0., float(i) / uni.iResolution.y) * RADIUS).xyz;
    }
  
    for(uint i = 0; i < ITERATIONS / 4; i++) {
      sum += tex.sample(iChannel0, uv - float2(0., float(i) / uni.iResolution.y) * RADIUS).xyz;
    }
    return float4(sum / float(ITERATIONS + 1), 1.);
  }

  if (in.value.onepass) {
    float hor = 1. / uni.iResolution.x;
    float ver = 1. / uni.iResolution.y;
    const float iter = 5.;

    float4 pic = tex.sample(iChannel0,uv)/(iter * 10.);

    for (float i = 0.;i < iter;i++)
    {
      pic += tex.sample(iChannel0,uv+float2(hor*i,0.0)) / (iter * 10.);
      pic += tex.sample(iChannel0,uv+float2(-hor*i,0.0)) / (iter * 10.);
      pic += tex.sample(iChannel0,uv+float2(0.0,ver*i)) / (iter * 10.);
      pic += tex.sample(iChannel0,uv+float2(0.0,-ver*i)) / (iter * 10.);

      pic += tex.sample(iChannel0,uv+float2(hor*i,ver*i)) / (iter * 10.);
      pic += tex.sample(iChannel0,uv+float2(-hor*i,ver*i)) / (iter * 10.);
      pic += tex.sample(iChannel0,uv+float2(hor*i,-ver*i)) / (iter * 10.);
      pic += tex.sample(iChannel0,uv+float2(-hor*i,-ver*i)) / (iter * 10.);
    }

    return float4(pic);

  }

  if (in.value.grainy) {
    const float dist = 4.0; // how far to sample from
    const int loops = 6; // how many times to sample, more = smoother

    float4 t = float4(0.0);

    float2 texel = 1.0 / uni.iResolution.xy;
    float2 d = texel * dist;

    for(int i = 0; i < loops; i++){

      float r1 = clamp(rand(uv * float(i))*2.0-1.0, -d.x, d.x);
      float r2 = clamp(rand(uv * float(i+loops))*2.0-1.0, -d.y, d.y);

      t += tex.sample(iChannel0, uv + float2(r1 , r2));
    }

    t /= float(loops);

    return t;

  }

  if (in.value.dfbox) {

    const int   c_samplesX    = 15;  // must be odd
    const int   c_samplesY    = 15;  // must be odd
    const float c_textureSize = 512.0;
    const float c_pixelSize = (1.0 / c_textureSize);
    const int   c_halfSamplesX = c_samplesX / 2;
    const int   c_halfSamplesY = c_samplesY / 2;

    int c_distX = uni.mouseButtons
    ? int(float(c_halfSamplesX+1) * uni.iMouse.x )
    : int((sin(uni.iTime*2.0)*0.5 + 0.5) * float(c_halfSamplesX+1));

    int c_distY = uni.mouseButtons
    ? int(float(c_halfSamplesY+1) * uni.iMouse.y )
    : int((sin(uni.iTime*2.0)*0.5 + 0.5) * float(c_halfSamplesY+1));

    float c_pixelWeight = 1.0 / float((c_distX*2+1)*(c_distY*2+1));

    float3 ret = float3(0);
    for (int iy = -c_halfSamplesY; iy <= c_halfSamplesY; ++iy)
    {
      for (int ix = -c_halfSamplesX; ix <= c_halfSamplesX; ++ix)
      {
        if (abs(float(iy)) <= float(c_distY) && abs(float(ix)) <= float(c_distX))
        {
          float2 offset = float2(ix, iy) * c_pixelSize;
          ret += tex.sample(iChannel0, uv + offset).rgb * c_pixelWeight;
        }
      }
    }
    return float4(ret, 1);
  }

  // otherwise
  return 0.5;
}
