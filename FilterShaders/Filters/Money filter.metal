
#define shaderName money_filter

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  float2 xy = thisVertex.where.xy / uni.iResolution.yy;
  
  float amplitud = 0.03;
  float frecuencia = 10.0;
  float gris = 1.0;
  float divisor = 4.8 / uni.iResolution.y;
  float grosorInicial = divisor * 0.2;
  
  const int kNumPatrones = 6;
  
  float3 datosPatron[kNumPatrones];
  datosPatron[0] = float3(-0.7071, 0.7071, 3.0); // -45
  datosPatron[1] = float3(0.0, 1.0, 0.6); // 0
  datosPatron[2] = float3(0.0, 1.0, 0.5); // 0
  datosPatron[3] = float3(1.0, 0.0, 0.4); // 90
  datosPatron[4] = float3(1.0, 0.0, 0.3); // 90
  datosPatron[5] = float3(0.0, 1.0, 0.2); // 0
  
  float4 color = tex.sample(iChannel0, float2(thisVertex.where.xy.x / uni.iResolution.x, xy.y));
  float4 fragColor = color;
  
  for(int i = 0; i < kNumPatrones; i++)
  {
    float coseno = datosPatron[i].x;
    float seno = datosPatron[i].y;
    
    float2 punto = float2(
                          xy.x * coseno - xy.y * seno,
                          xy.x * seno + xy.y * coseno
                          );
    
    float grosor = grosorInicial * float(i + 1);
    float dist = mod(punto.y + grosor * 0.5 - sin(punto.x * frecuencia) * amplitud, divisor);
    float brillo = 0.3 * color.r + 0.4 * color.g + 0.3 * color.b;
    
    if(dist < grosor && brillo < 0.75 - 0.12 * float(i))
    {
      // Suavizado
      float k = datosPatron[i].z;
      float x = (grosor - dist) / grosor;
      float fx = abs((x - 0.5) / k) - (0.5 - k) / k;
      gris = min(fx, gris);
    }
  }

  fragColor = float4(gris, gris, gris, 1.0);
  return fragColor;
}
