
#define shaderName video_billboarding

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

static float3 effect(float2 uv, float3 col, float yVar, float2 s, texture2d<float> vid)
{
  float grid = yVar * 10.+5.;
  float step_x = 0.0015625;
  float step_y = step_x * s.x / s.y;
  float offx = floor(uv.x  / (grid * step_x));
  float offy = floor(uv.y  / (grid * step_y));
  float3 res = vid.sample(iChannel0, (float2(offx * grid * step_x , offy * grid * step_y))).rgg;
  float2 prc = fract(uv / float2(grid * step_x, grid * step_y));
  float2 pw = pow(abs(prc - 0.5), float2(2.0));
  float  rs = pow(0.45, 2.0);
  float gr = smoothstep(rs - 0.1, rs + 0.1, pw.x + pw.y);
  float y = (res.r + res.g + res.b) / 3.0;
  // float3 ra = res / y;
  float ls = 0.3;
  float lb = ceil(y / ls);
  float lf = ls * lb + 0.3;
  res = lf * res;
  col = mix(res, float3(0.1, 0.1, 0.1), gr);
  return col;
}

fragmentFn(texture2d<float> texz) {
  
  float2 s = uni.iResolution.xy;
  float2 g = thisVertex.where.xy;
  float2 m = (!uni.mouseButtons) ? m = s/2.:uni.iMouse.xy * uni.iResolution.xy;
  float yVar = m.y/s.y;
  float2 uv = textureCoord;
  float3 tex = texz.sample(iChannel0, uv).rgg;
  float3 col = g.x<m.x?effect(uv,tex, yVar, s, texz):tex;
  col = mix( col, float3(0.), 1.-smoothstep( 1., 2., abs(m.x-g.x) ) );
  return float4(col,1.);
}
