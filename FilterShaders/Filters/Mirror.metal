
#define shaderName mirror

#include "Common.h" 

#define MIR_VER
//#define MIR_VER_REVERSE
//#define MIR_HOR
//#define MIR_HOR_REVERSE
//#define MIR_4
//#define MIR_4_REVERSE

fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;

#if defined(MIR_VER)
  if(uv.x > 0.5){
    uv.x = 0.5 - (uv.x - 0.5);
  }
#elif defined(MIR_VER_REVERSE)
  if(uv.x < 0.5){
    uv.x = 0.5 - uv.x;
  }
  else{
    uv.x -= 0.5;
  }
#elif defined(MIR_HOR)
  if(uv.y < 0.5){
    uv.y = 0.5 - uv.y;
  }
  else{
    uv.y -= 0.5;
  }
#elif defined(MIR_HOR_REVERSE)
  if(uv.y > 0.5){
    uv.y = 0.5 - (uv.y - 0.5);
  }
#elif defined(MIR_4)
  if(uv.x > 0.5){
    uv.x = 0.5 - (uv.x - 0.5);
  }
  if(uv.y < 0.5){
    uv.y = 0.5 - uv.y;
  }
  else{
    uv.y -= 0.5;
  }
#elif defined(MIR_4_REVERSE)
  if(uv.x > 0.5){
    uv.x = 0.5 - (uv.x - 0.5);
  }
  if(uv.y > 0.5){
    uv.y = 0.5 - (uv.y - 0.5);
  }
#endif


  return tex.sample(iChannel0, uv);
}
