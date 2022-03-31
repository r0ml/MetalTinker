
#define shaderName Brightness_contrast_saturation

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

static float4x4 brightnessMatrix( float brightness ) {
  return float4x4( 1, 0, 0, 0,
                  0, 1, 0, 0,
                  0, 0, 1, 0,
                  brightness,brightness,brightness, 1 );
}

static float4x4 contrastMatrix( float contrast ) {
  float t = ( 1.0 - contrast ) / 2.0;
  return float4x4( contrast, 0, 0, 0,
                  0, contrast, 0, 0,
                  0, 0, contrast, 0,
                  t, t, t, 1 );
  
}

static float4x4 saturationMatrix( float saturation ) {
  float3 luminance = float3( 0.3086, 0.6094, 0.0820 );
  float oneMinusSat = 1.0 - saturation;
  
  float3 red = float3( luminance.x * oneMinusSat );
  red+= float3( saturation, 0, 0 );
  
  float3 green = float3( luminance.y * oneMinusSat );
  green += float3( 0, saturation, 0 );
  
  float3 blue = float3( luminance.z * oneMinusSat );
  blue += float3( 0, 0, saturation );
  
  return float4x4( float4(red,     0) ,
                  float4(green,   0) ,
                  float4(blue,    0) ,
                  float4(0, 0, 0, 1) );
}

constant const float brightness = 0.15;
constant const float contrast = 1.2;
constant const float saturation = 1.5;

fragmentFn(texture2d<float> tex) {
  float4 color = tex.sample( iChannel0, textureCoord );
  return brightnessMatrix( brightness ) *  contrastMatrix( contrast ) *  saturationMatrix( saturation ) * color;
}
