
#define shaderName mobius_transformation

#include "Common.h" 

struct InputBuffer {};
initialize() {}

fragmentFn() {
  float2 p = worldCoordAspectAdjusted / 2;
    p.y += 0.45;
    
    float a = cos(uni.iTime);
    float b = sin(uni.iTime);
    float c = -sin(uni.iTime);
    float d = cos(uni.iTime); // SL(2,R)
    
    float nx = p.x * a + b;
    float ny = p.y * a;
    float dx = p.x * c + d;
    float dy = p.y * c;
    float deno = dx*dx + dy*dy;
    float numex = nx * dx + ny * dy;
    float numey = ny * dx - nx * dy;
    p = float2(numex, numey) / deno;
    
    float arg = atan2(p.y,p.x);
    float len = length(p);
    float3 hue = cos(float3(0,1,-1)*2./3.*PI + arg) * 0.5 + 0.5;
    float lum = 1.;
    lum *= pow(-cos(len * 30.) * 0.5 + 0.5, 0.1);
    lum *= pow(-cos(p.x * 30.) * 0.5 + 0.502, 0.03);
    lum *= pow(-cos(p.y * 30.) * 0.5 + 0.502, 0.03);
    float3 col = hue * lum; 
    return float4(col,1.0);
}

 
