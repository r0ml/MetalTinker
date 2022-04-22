
#define shaderName Automated_Automata

#include "Common.h"

constant float4 white = float4(1., 1., 1., 1.);
constant float4 black = float4(0., 0., 0., 1.);
constant float4 red = float4(0., 1., 0., 1.);
// Change this to change the rule, 0-255
// 126 is a sierpinski triangle
// good other values 30, 54, 60, 62, 90, 94, 102, 110, 122
// 126, 150, 152, 182, 188, 190, 220, 222, 250
constant int rule = 100;

/////////////////////////////////////////////
// Automated Automata
//
// Based on Simple Cellular Autonoma by sobokhan
// @ https://www.shadertoy.com/view/Xty3WR
//
// Cycles through various automatas. Also prints
// bitmap font numbers using a technique which
// stores them in an uncompressed, easily
// editable form.
//


fragmentFn(texture2d<float> lastFrame) {
  float2 winCoord = thisVertex.where.xy;
  
  int PIX_size = int(min(10.0, ceil(uni.iResolution.y/ 60.0- 2.0)+ 2.0));
  //    int2 PIX_XY = int2(0);
  //    int2 PIX_xy = int2(0);
  //    float4 PIX_on = float4(0.2* thisVertex.where.y/ uni.iResolution.y+ 0.3, 0.8- 0.5* thisVertex.where.y/ uni.iResolution.y, 1, 1);
  float4 PIX_color = float4(0);
  float2 iResolution0 = uni.iResolution.xy;
  float2 glFragResolution = ceil(iResolution0/ float2(1, 4));
  float2 glFragCoord = floor(mod(winCoord, glFragResolution))+ 0.5;

  float iTime = float(uni.iFrame);
  int x = int(glFragCoord.x);
  int y = int(glFragCoord.y);
  int w = int(glFragResolution.x);
  int h = int(glFragResolution.y);
  int t = uni.iFrame - uni.iFrame/ h* h;
  int u = int(mod((iTime- thisVertex.where.y)/ glFragResolution.y, 256.0));
  float4 rb[8];
  // get our texture coordinate
  //	float2 uv = thisVertex.where.xy / iResolution0;
  // get the color from the last render
  float4 fragColor = lastFrame.read(uint2(winCoord));

  int r = rule+ u;
  r -= r/ 256* 256;
  int printedRule = rule+ u+ 255;
  printedRule -= printedRule/ 256* 256;
  for(int i = 7; i>= 0; i--) {
    int v = int(pow(2., float(i)));
    if(r >= v) {
      r -= v;
      rb[i] = black;
    } else if(i- i/ 2* 2< 1) {
      rb[i] = red;
    } else {
      rb[i] = white;
    }
  }

  if(thisVertex.where.y== 0.5) {
    // initialize the screen
    if(x- x/ (w/ 4)* (w/ 4)== (w/ 8)) {
      fragColor = black;
    } else fragColor = white;
  } else if(uni.iFrame== 0|| x< 2) {
    fragColor = white;
  } else if(y== t) {
    // get those lines after the first
    uint2 puv[3];
    float4 pixel[3];
    puv[0] = uint2(clamp(int2(winCoord) + int2( -1., -1.), 0, int2(iResolution0-1)));
    puv[1] = uint2(clamp(int2(winCoord) + int2(  0., -1.), 0, int2(iResolution0-1)));
    puv[2] = uint2(clamp(int2(winCoord) + int2( +1., -1.), 0, int2(iResolution0-1)));
    pixel[0] = lastFrame.read( puv[0]);
    pixel[1] = lastFrame.read( puv[1]);
    pixel[2] = lastFrame.read( puv[2]);
    int index = (all(pixel[0] == black) ? 1 : 0)+ ( all(pixel[1]== black) ? 2 : 0)+ ( all(pixel[2]== black) ? 4 : 0);
    if(index== 0) fragColor = rb[0];
    else if(index== 1) fragColor = rb[1];
    else if(index== 2) fragColor = rb[2];
    else if(index== 3) fragColor = rb[3];
    else if(index== 4) fragColor = rb[4];
    else if(index== 5) fragColor = rb[5];
    else if(index== 6) fragColor = rb[6];
    else if(index== 7) fragColor = rb[7];

  }
  // adjust number to hide the switch
  int ny = t+ h+ (y< h/ 2 ? 6* PIX_size : 0);
  ny = ny- ny/ h* h+ (y< h/ 2 ? 0 : 6* PIX_size);
  //	printUInt8(printedRule, int2(5, ny));
  return mix(fragColor, PIX_color, PIX_color.a);
}
