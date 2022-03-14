
#define shaderName screen_chromatic_aberration

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

constant const float redShift = 100.0;
constant const float greenShift = 50.0;
constant const float blueShift = 15.0;
constant const float aberrationStrength = 1.0;

static float bx2(float x)
{
  return x * 2.0 - 1.0;
}

fragmentFn(texture2d<float> tex) {
  float2 texelSize = float2(1.0, 1.0) / uni.iResolution.xy;
  float2 uv = textureCoord;
  float2 mouse = uni.iMouse.xy;
  
  float uvXOffset = bx2(uv.x);
  float mouseXOffset = uni.mouseButtons ? bx2(mouse.x) : 0.0;
  
  float uvXFromCenter = uvXOffset - mouseXOffset;
  float finalUVX = uvXFromCenter * abs(uvXFromCenter) * aberrationStrength;
  
  float redChannel = tex.sample(iChannel0, float2(uv.x + (finalUVX * (redShift * texelSize.x)), uv.y)).r;
  float greenChannel = tex.sample(iChannel0, float2(uv.x + (finalUVX * (greenShift * texelSize.x)), uv.y)).g;
  float blueChannel = tex.sample(iChannel0, float2(uv.x + (finalUVX * (blueShift * texelSize.x)), uv.y)).b;
  
  return float4(redChannel, greenChannel, blueChannel, 1.0);
}
