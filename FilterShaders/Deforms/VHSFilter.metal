
#define shaderName vhsfilter

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  
  // distance from center of image, used to adjust blur
  float2 uv = textureCoord;
  float d = length(uv - float2(0.5,0.5));
  
  // blur amount
  float blur = 0.02;
  //blur = (1.0 + sin(uni.iTime*6.0)) * 0.5;
  //blur *= 1.0 + sin(uni.iTime*16.0) * 0.5;
  //blur = pow(blur, 3.0);
  //blur *= 0.05;
  // reduce blur towards center
  //blur *= d;
  
  float myTime = scn_frame.time * 1.0;
  
  // fragColor = texture( iChannel0, float2(uv.x + sin( (uv.y + sin(myTime)) * abs(sin(myTime) + sin(2.0 * myTime) + sin(0.3 * myTime) + sin(1.4 * myTime) + cos(0.7 * myTime) + cos(1.3 * myTime)) * 4.0 ) * 0.02,uv.y) );
  
  float2 myuv =  float2(uv.x + sin( (uv.y + sin(myTime)) * abs(sin(myTime) + sin(2.0 * myTime) + sin(0.3 * myTime) + sin(1.4 * myTime) + cos(0.7 * myTime) + cos(1.3 * myTime)) * 4.0 ) * 0.02,uv.y) ;
  
  // final color
  float3 col;
  col.r = tex.sample( iChannel0, float2(myuv.x+blur,myuv.y) ).r;
  col.g = tex.sample( iChannel0, myuv ).g;
  col.b = tex.sample( iChannel0, float2(myuv.x-blur,myuv.y) ).b;
  
  // scanline
  float scanline = sin(uv.y*400.0)*0.08;
  col -= scanline;
  
  // vignette
  col *= 1.0 - d * 0.5;
  
  return float4(col,1.0);
}
