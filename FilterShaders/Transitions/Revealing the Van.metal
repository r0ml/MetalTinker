
#define shaderName Revealing_the_Van

#include "Common.h"

struct InputBuffer {
};

initialize() {
//  setTex(0, asset::kinetic_art);
//  setTex(1, asset::diving); // vandamme
}






//global variables

//kernels
constant const float3x3 blur = float3x3(
                                        0.111, 0.111, 0.111, // first column (not row!)
                                        0.111, 0.111, 0.111, // second column
                                        0.111, 0.111, 0.111 // third column
                                        );

constant const float3x3 identity = float3x3(
                                            0.0, 0.0, 0.0, // first column (not row!)
                                            0.0, 1.0, 0.0, // second column
                                            0.0, 0.0, 0.0 // third column
                                            );

constant const float3x3 edgeDetect = float3x3(
                                              1.0, 0.0, -1.0, // first column (not row!)
                                              0.0, 0.0, 0.0, // second column
                                              -1.0, 0.0, 1.0 // third column
                                              );

constant const float3x3 sharpen = float3x3(
                                           0., -1, 0.0, // first column (not row!)
                                           -1, 5, -1, // second column
                                           0., -1, 0.0 // third column
                                           );

//pseudo-literals
// constant const float2 Location = float2(0.5, 0.4);
constant const float Radius = 0.2;
constant const float4 ZeroColor = float4(0.0,0.0,0.0,0.0);

//helper functions

//conditionals
//return either 0.0 or 1.0
/*static float when_eq(float x, float y) {
  return 1.0 - abs(sign(x - y));
}*/

/*
static float when_neq(float x, float y) {
  return abs(sign(x - y));
}*/

static float when_gt(float x, float y) {
  return max(sign(x - y), 0.0);
}

static float when_lt(float x, float y) {
  return max(sign(y - x), 0.0);
}

//image processing
static float4 sample(const int x, const int y, float2 winCoord, texture2d<float> tex, float2 textResolution, float2 reso)
{
  float2 uv = winCoord / reso * textResolution.xy;
  uv = (uv + float2(x, y)) / textResolution.xy ;
  return tex.sample(iChannel0, uv);
}

static float4 filter(float2 uv, float3x3 kernelx , texture2d<float> tex, float2 textResolution, float2 reso)
{
  float4 sum = sample(-1, -1, uv, tex, textResolution, reso) * kernelx[0][0]
  + sample(-1,  0, uv, tex, textResolution, reso) * kernelx[0][1]
  + sample(-1,  1, uv, tex, textResolution, reso) * kernelx[0][2]
  + sample( 0, -1, uv, tex, textResolution, reso) * kernelx[1][0]
  + sample( 0,  0, uv, tex, textResolution, reso) * kernelx[1][1]
  + sample( 0,  1, uv, tex, textResolution, reso) * kernelx[1][2]
  + sample( 1, -1, uv, tex, textResolution, reso) * kernelx[2][0]
  + sample( 1,  0, uv, tex, textResolution, reso) * kernelx[2][1]
  + sample( 1,  1, uv, tex, textResolution, reso) * kernelx[2][2];
  
  return sum;
}


fragmentFn(texture2d<float> tex0, texture2d<float> tex1)
{
  
  float2 uv = thisVertex.where.xy.xy / uni.iResolution.xy;
  float2 m = uni.iMouse ;
  
  //Correct for aspect ratio
  float2 newUV = uv;
  newUV.y *= uni.iResolution.y / uni.iResolution.x;
  
  
  //Kernels avalible: blur, sharpen, identity, edgeDetect
  
  //kernel0 used on iChannel0
  float3x3 kernel0 = blur;
  //kernel1 used on iChannel1
  float3x3 kernel1 = sharpen;
  
  float4 Layer1 = ::filter(thisVertex.where.xy, kernel0, tex0, textureSize(tex0), uni.iResolution);
  float4 Layer2 = ::filter(thisVertex.where.xy, kernel1, tex1, textureSize(tex1), uni.iResolution);
  
  float4 color = ZeroColor; //must be zero initalized
  
  //color = layer1 when: length(m.xy - newUV) > Radius
  color += when_gt(length(m.xy - newUV), Radius) * Layer1;
  
  //color = layer2 when: length(m.xy - newUV) < Radius
  color += when_lt(length(m.xy - newUV), Radius) * Layer2;
  
  return color;
}
