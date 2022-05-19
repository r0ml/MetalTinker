
#define shaderName texture_wave_tutorial

#include "Common.h" 

fragmentFunc(texture2d<float> tex) {
  // get % coords
  float2 r = textureCoord;
  
  // calculate wave(height) argument
  // make sin of r.x work faster by "r.y * 10.0"
  // make time dependency with sin() period
  // and increment speed with "* 5.0"
  float sinValue = r.y * 10.0 + mod(scn_frame.time, M_PI_F * 2.0) * 5.0;
  
  // add dx to r.x
  // don't forget about % - "/ 20.0"
  r.x = r.x + sin(sinValue) / 20.0;
  
  float4 t = tex.sample(iChannel0, r);
  return t;
}
