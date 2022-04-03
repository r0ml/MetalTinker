
#define shaderName simple_rippleradialdistortion

#include "Common.h" 

static float radial(float2 pos, float radius)
{
  float result = length(pos)-radius;
  result = fract(result*1.0);
  float result2 = 1.0 - result;
  float fresult = result * result2;
  fresult = pow((fresult*5.5),10.0);
  //fresult = clamp(0.0,1.0,fresult);
  return fresult;
}

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  
  float2 c_uv = worldCoord;
  float2 o_uv = uv * 0.80;
  float gradient = radial(c_uv, uni.iTime*0.5);
  float2 fuv = mix(uv,o_uv,gradient);
  float3 col = tex.sample(iChannel0,fuv).xyz;
  return float4(col,1.0);
}

