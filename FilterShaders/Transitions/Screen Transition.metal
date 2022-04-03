
#define shaderName screen_transition

#include "Common.h" 

fragmentFn(texture2d<float> tex) {
  // Convert gametime to a rotating value between 0 and 1
  float time = mod(uni.iTime, 5.0) / 5.0;
  // Calculate the UV coordinates
  float2 uv = textureCoord;
  
  // Get the rgba value at the current UV coordinate
  // of the transition texture
  float4 transit = tex.sample( iChannel0, uv );
  
  // If the b value of the transition texture at the
  // current UV coordinate is less than the current
  // 0-1 time value display the pixel as the transition color
  if (transit.b < time) {
    // Set the current pixel to the transition color
    // In this case black
    return float4(0, 0, 0, 1);
  } else {
    return tex.sample( iChannel0, uv ); // <- Use the transition texture if it's a color image for an interesting transition effect.
  }
  
}

 
