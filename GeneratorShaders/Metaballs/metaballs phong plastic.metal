
#define shaderName metaballs_phong_plastic

#include "Common.h" 

static float dot2(float3 p) {
  return dot(p,p);
}

static float map(float3 p, float time) {
  float len = 0.0;
  
  for(float i = 1.0; i < 20.0; i++) {
    float3 sphere = float3(sin(time*i*0.1),cos(time*i*0.12),0.0)*10.0;
    len += 1.0/dot2(p-sphere);
  }
  
  return (inversesqrt(len)-1.0)*3.0;
}

static float3 findcolor(float3 p, float time) {
  float len = 10000.0;
  float3 color = float3(0.0);
  for(float i = 1.0; i < 20.0; i++) {
    float len2 = (dot2(p-float3(sin(time*i*0.1),cos(time*i*0.12),0.0)*10.0));
    
    //random colors
    color = mix(float3(sin(i*9.11)*0.5+0.5,fract(1.0/fract(i*PI)),fract(i*PI)),
                color, saturate((len2-len)*0.1+0.5));
    
    len = mix(len2,len,saturate((len2-len)*0.1+0.5));
  }
  return color;
}

static float3 findnormal(float3 p, float time) {
  float2 eps = float2(0.01,0.0);
  
  return normalize(float3(
                          map(p+eps.xyy, time)-map(p-eps.xyy, time),
                          map(p+eps.yxy, time)-map(p-eps.yxy, time),
                          map(p+eps.yyx, time)-map(p-eps.yyx, time)));
}

fragmentFunc() {
  float2 uv = worldCoordAdjusted;
  
  float3 ro = float3(0.0,0.0,-15.0);
  float3 rd = normalize(float3(uv,1));
  float len = 0.0;
  float dist = 0.0;
  float t = scn_frame.time;

  for (int i = 0; i < 50; i++) {
    len = map(ro, t);
    dist += len;
    ro += rd * len;
    if (dist > 30.0 || len < 0.01) {
      break;
    }
  }
  
  float4 fragColor = 0;
  if (dist < 30.0 && len < 0.01) {
    float3 sun = normalize(float3(-1.0));
    float3 objnorm = findnormal(ro, t);
    float3 reflectnorm = reflect(rd,objnorm);
    float3 color = findcolor(ro, t);
    fragColor = float4(color*max(0.2,0.8*dot(objnorm,sun)),1.0);
    fragColor = max(fragColor,(dot(reflectnorm,sun)-0.9)*12.0);
  }
  return sqrt(fragColor);
}
