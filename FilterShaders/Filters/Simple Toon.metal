
#define shaderName simple_toon

#include "Common.h" 

#define s2(a, b)				temp = a; a = min(a, b); b = max(temp, b);
#define mn3(a, b, c)			s2(a, b); s2(a, c);
#define mx3(a, b, c)			s2(b, c); s2(a, c);

#define mnmx3(a, b, c)			mx3(a, b, c); s2(a, b);                                   // 3 exchanges
#define mnmx4(a, b, c, d)		s2(a, b); s2(c, d); s2(a, c); s2(b, d);                   // 4 exchanges
#define mnmx5(a, b, c, d, e)	s2(a, b); s2(c, d); mn3(a, c, e); mx3(b, d, e);           // 6 exchanges
#define mnmx6(a, b, c, d, e, f) s2(a, d); s2(b, e); s2(c, f); mn3(a, b, c); mx3(d, e, f); // 7 exchanges

constant const float3x3 sx = float3x3(
                                      1.0, 2.0, 1.0,
                                      0.0, 0.0, 0.0,
                                      -1.0, -2.0, -1.0
                                      );

constant const float3x3 sy = float3x3(
                                      1.0, 0.0, -1.0,
                                      2.0, 0.0, -2.0,
                                      1.0, 0.0, -1.0
                                      );

static float3 toon(float2 uv, texture2d<float> vid0) {
  float4 texel = vid0.sample(iChannel0, uv);
  float3 c = texel.rgb;
  float3 f = float3(3.,5.,6.);
  c = rgb2hsv(c);
  c = floor(c * f) / f;
  return c;
}

static float3 median(float2 uv, float2 tsize, texture2d<float> vid0) {
  
  float3 v[9];
  float3x3 I;
  
  for(int dX = -1; dX <= 1; ++dX) {
    for(int dY = -1; dY <= 1; ++dY) {
      float2 offset = float2(float(dX), float(dY));
      float3 c = toon(uv.xy + offset * tsize, vid0);
      v[(dX + 1) * 3 + (dY + 1)] = c;
      I[dX + 1][dY + 1] = c.x * c.y * c.z;
      
    }
  }
  
  float3 temp;
  float3 orig = v[4];
  // Starting with a subset of size 6, remove the min and max each time
  mnmx6(v[0], v[1], v[2], v[3], v[4], v[5]);
  mnmx5(v[1], v[2], v[3], v[4], v[6]);
  mnmx4(v[2], v[3], v[4], v[7]);
  mnmx3(v[3], v[4], v[8]);
  
  float gx = dot(sx[0], I[0]) + dot(sx[1], I[1]) + dot(sx[2], I[2]);
  float gy = dot(sy[0], I[0]) + dot(sy[1], I[1]) + dot(sy[2], I[2]);
  
  float g = sqrt(pow(gx, 2.0)+pow(gy, 2.0));
  return mix(v[4], orig, g) - g;
}


fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  
  float3 c = median(uv, 1.6 / uni.iResolution.xy, tex);
  c = hsv2rgb(c);
  return float4(c,1.0);
}
