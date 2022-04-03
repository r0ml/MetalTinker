
#define shaderName mmcmask

#include "Common.h" 
 
static float squircle(float2 pos, float radius, float power, const float2 uv){
  float2 p = abs(pos - uv) / radius;
  float d = (pow(p.x,power) + pow(p.y, power) - pow(radius, power)) -1.0;
  return 1.0 - saturate (46.0*d );
}

static float fu(float2 pos, float size, thread float2& uv){
  uv = uv * rot2d(0.5);
  uv.y*=0.9;
  float a = squircle(float2(pos.x-.4,pos.y-.9),size*1.1, 1.6, uv);
  uv.x*=1.1;
  float b = squircle(float2(pos.x-0.3,pos.y+.6),size*0.9, 1.6, uv);
  return a*b;
}

fragmentFn(texture2d<float> texz) {
  float2 uv = worldCoordAspectAdjusted;
  uv.x-=0.2;
  float4 tex = texz.sample(iChannel0, textureCoord);
  float e = fu(float2(0),1.0, uv);
  float f = fu(float2(0.8,-0.6),0.7, uv);
  float g = fu(float2(-0.1,1.5),0.62, uv);
  return mix(float4(1.0),tex,saturate(e+f+g));
}

 
