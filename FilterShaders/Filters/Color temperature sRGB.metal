/** 
 Author: BeRo
 Color temperature
 */
#define shaderName Color_temperature_sRGB

#include "Common.h"

struct InputBuffer {
  bool WithQuickAndDirtyLuminancePreservation = true;
};

initialize() {
}




// Color temperature (sRGB) stuff

constant const float LuminancePreservationFactor = 1.0;

// Valid from 1000 to 40000 K (and additionally 0 for pure full white)
float3 colorTemperatureToRGB(const float temperature){
  // Values from: http://blenderartists.org/forum/showthread.php?270332-OSL-Goodness&p=2268693&viewfull=1#post2268693
  float3x3 m = (temperature <= 6500.0) ? float3x3(float3(0.0, -2902.1955373783176, -8257.7997278925690),
                                                  float3(0.0, 1669.5803561666639, 2575.2827530017594),
                                                  float3(1.0, 1.3302673723350029, 1.8993753891711275)) :
  float3x3(float3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
           float3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
           float3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));
  return mix(clamp(float3(m[0] / (float3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2]), float3(0.0), float3(1.0)), float3(1.0), smoothstep(1000.0, 0.0, temperature));
}


fragmentFn(texture2d<float> tex) {
  float2 uv = textureCoord;
  float temperature = uni.mouseButtons ? mix(1000.0, 40000.0, uni.iMouse.x ) : 6550.0; // mix(1000.0, 15000.0, (sin(uni.iTime * (TAU / 10.0)) * 0.5) + 0.5);
  float temperatureStrength = uni.mouseButtons ? (1.0 - saturate((uni.iMouse.y ) * (1.0 / 0.9))) : 1.0;
  if(uv.y > 0.1){
    float3 inColor = tex.sample(iChannel0, uv).xyz;
    float3 outColor = mix(inColor, inColor * colorTemperatureToRGB(temperature), temperatureStrength);
    if (in.WithQuickAndDirtyLuminancePreservation) {
    outColor *= mix(1.0, luminance(inColor) / max(luminance(outColor), 1e-5), LuminancePreservationFactor);
    }
    return float4(outColor, 1.0);
  }else{
    float2 f = float2(1.5) / uni.iResolution.xy;
    return float4(mix(colorTemperatureToRGB(mix(1000.0, 40000.0, uv.x)), float3(0.0), min(min(smoothstep(uv.x - f.x, uv.x, (temperature - 1000.0) / 39000.0),
                                                                                              smoothstep(uv.x + f.x, uv.x, (temperature - 1000.0) / 39000.0)),
                                                                                          1.0 - min(smoothstep(0.04 - f.y, 0.04, uv.y),
                                                                                                    smoothstep(0.06 + f.y, 0.06, uv.y)))),
                  1.0);
  }
}
