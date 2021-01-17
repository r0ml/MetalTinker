
#define shaderName Box_Breathing_Remix

#include "Common.h"

struct InputBuffer { };
initialize() {}


#define _Smooth(p,r,s) smoothstep(-s, s, p-(r))

#define CYCLE_DURATION 16.


//I need to add comment to make this more readable

//edit added code to handle phone in portrait mode

fragmentFn() {
  float2 uv = worldCoordAspectAdjusted / 2;
  float smoothFactor = 0.001;

  float len = length(uv);
  
  float time = fract(uni.iTime / CYCLE_DURATION);
  
  
  float4 fragColor = float4(1.);
  float backRadius = .4;
  float background = _Smooth(len,backRadius,.00001);
  
  float4 backgroundColor = float4(.8);
  
  fragColor = mix(fragColor,backgroundColor,background);
  
  float4 circleColor = float4(0.,0.,1.,1.);
  
  float circleMinRadius = .12;
  float circleMaxRadius = .36;
  
  float currentCircleProgression = (abs(time * 2. - 1.) * 2. - .5);
  currentCircleProgression = saturate(currentCircleProgression);
  currentCircleProgression = sin(currentCircleProgression * PI - PI / 2.) * .5 + .5;
  
  float innerCircle =1. - _Smooth(len, circleMinRadius + (circleMaxRadius - circleMinRadius) * currentCircleProgression, smoothFactor);
  
  
  fragColor = mix(fragColor,circleColor,innerCircle);
  
  
  float rimThikness = .025;
  float rim =_Smooth(len, backRadius - rimThikness,smoothFactor) * _Smooth(backRadius + rimThikness,len,smoothFactor);
  
  float4 rimColor = float4(0.,0.,0.,1.);
  float angle = atan2(uv.y,uv.x);
  float4 rimFilledColor = float4(.1,.2,.1,1.);
  
  float rimAnimationSpeed = PI * 2. * 2. ;
  
  float timeOffset = -2.;
  time = fract((uni.iTime + timeOffset) / CYCLE_DURATION);
  
  float fill = _Smooth(angle + PI ,time * rimAnimationSpeed,smoothFactor);
  float unFill =  1. - _Smooth(angle + PI ,(time - .5) * rimAnimationSpeed,smoothFactor);
  float separator = step(time,.5);
  float currentFill = separator * fill + (1. - separator) * unFill;
  
  rimColor = mix(rimColor,rimFilledColor,currentFill);
  
  return mix(fragColor,rimColor,rim);
}
