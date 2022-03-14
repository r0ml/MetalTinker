
#define shaderName vhs_pause_effect

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

fragmentFn(texture2d<float> tex) {
  float4 texColor = float4(0);
  // get position to sample
  float2 samplePosition = textureCoord;
  float whiteNoise = 9999.0;
  
  // Jitter each line left and right
  samplePosition.x = samplePosition.x+(rand(float2(uni.iTime,thisVertex.where.y))-0.5)/64.0;
  // Jitter the whole picture up and down
  samplePosition.y = samplePosition.y+(rand(float2(uni.iTime))-0.5)/32.0;
  // Slightly add color noise to each line
  texColor = texColor + (float4(-0.5)+float4(rand(float2(thisVertex.where.y,uni.iTime)),rand(float2(thisVertex.where.y,uni.iTime+1.0)),rand(float2(thisVertex.where.y,uni.iTime+2.0)),0))*0.1;
  
  // Either sample the texture, or just make the pixel white (to get the staticy-bit at the bottom)
  whiteNoise = rand(float2(floor(samplePosition.y*80.0),floor(samplePosition.x*50.0))+float2(uni.iTime,0));
  if (whiteNoise > 11.5-30.0*samplePosition.y || whiteNoise < 1.5-5.0*samplePosition.y) {
    // Sample the texture.
    // samplePosition.y = 1.0-samplePosition.y; //Fix for upside-down texture
    texColor = texColor + tex.sample(iChannel0,samplePosition);
  } else {
    // Use white. (I'm adding here so the color noise still applies)
    texColor = float4(1);
  }
  return texColor;
}
