/** 
 Author: demofox
 Shadertoy has a blue noise texture now, yay!
 
 Left: blue noise. Right: white noise.
 
 Check bottom of shader for notes.
 */
#define shaderName Blue_Noise_Dissolve

#include "Common.h"

struct InputBuffer {
};

initialize() {
}




#define ANIMATE_NOISE 0
#define HAS_GREEN_SCREEN 0

//----------------------------------------------------------------------------------------
///  1 out, 3 in...
// from https://www.shadertoy.com/view/4djSRW
#define HASHSCALE1 443.8975
float hash13(float3 p3)
{
  p3  = fract(p3 * HASHSCALE1);
  p3 += dot(p3, p3.yzx + 19.19);
  return fract((p3.x + p3.y) * p3.z);
}

fragmentFn(texture2d<float> tex)
{   
  // const float c_goldenRatioConjugate = 0.61803398875;
  
  // use default "new shadertoy" as background
  float2 uv = thisVertex.where.xy/uni.iResolution.xy;
  float3 bg = 0.5 + 0.5*cos(uni.iTime+uv.xyx+float3(0,2,4));
  
  // foreground color
  float3 fg = tex.sample( iChannel0, uv ).rgb;
  
  // handle greenscreen if there is one
  // This is for the textures with greenscreen backgrounds
#if HAS_GREEN_SCREEN
  float opaque = (fg.g > 0.5 && fg.r < 0.2 && fg.b < 0.2) ? 0.0 : 1.0;
#else
  float opaque = 1.0;
#endif
  
  // animate transparency over time
  float alpha = (sin(uni.iTime*2.0)*0.5+0.5) * 1.2 - 0.1;
  
  // use blue noise to do a stochastic alpha
  float2 blueNoiseUV = thisVertex.where.xy / float2(1024.0, 1024.0);
  float blueNoise = interporand(blueNoiseUV).r;
#if ANIMATE_NOISE
  blueNoise = fract(blueNoise + float(iFrame%64) * c_goldenRatioConjugate);
  float whiteNoise = hash13(float3(uv, float(iFrame%256) / 256.0));
#else
  float whiteNoise = hash13(float3(uv, 0.0));
#endif
  if (uv.x > 0.5)
    opaque *= step(alpha, whiteNoise);
  else
    opaque *= step(alpha, blueNoise);
  
  // use the binary opaque value (opaque or not, no semi transparency)
  // to select background or foreground
  float3 col = mix(bg, fg, opaque);
  
  if (abs(uv.x - 0.5) < 0.001)
    col = float3(0.0, 1.0, 0.0);
  
  // Output to screen
  return float4(col,1.0);
}

/*
 
 Items of note!
 
 * The blue noise texture sampling should be set to "nearest" (not mip map!) and repeat
 
 * you should calculate the uv to use based on the pixel coordinate and the size of the blue noise texture.
 * aka you should tile the blue noise texture across the screen.
 * blue nois actually tiles really well unlike white noise.
 
 * A blue noise texture is "low discrepancy over space" which means there are fewer visible patterns than white noise
 * it also gives more even coverage vs white noise. no clumps or voids.
 
 * In an attempt to make it also blue noise over time, you can add the golden ratio and frac it.
 * that makes it lower discrepancy over time, but makes it less good over space.
 * thanks to r4unit for that tip! https://twitter.com/R4_Unit
 
 For more information:
 
 What the heck is blue nois:
 https://blog.demofox.org/2018/01/30/what-the-heck-is-blue-noise/
 
 Low discrepancy sequences:
 https://blog.demofox.org/2017/05/29/when-random-numbers-are-too-random-low-discrepancy-sequences/
 
 You can get your own blue noise textures here:
 http://momentsingraphics.de/?p=127
 
 */






