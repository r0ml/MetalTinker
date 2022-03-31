
#define shaderName ripple_distortion_warp

#include "Common.h" 
struct InputBuffer {
};

initialize() {
}

//CONTROL VARIABLES
constant const float uPower = 0.2; // barrel power - (values between 0-1 work well)
constant const float uSpeed = 5.0;
constant const float uFrequency = 5.0;

static float2 Distort(float2 p, float power, float speed, float freq, float time)
{
  float theta  = atan2(p.y, p.x);
  float radius = length(p);
  radius = pow(radius, power*sin(radius*freq-time*speed)+1.0);
  p.x = radius * cos(theta);
  p.y = radius * sin(theta);
  return float2(0.5, -0.5) * (p + 1.0);
}

fragmentFn(texture2d<float> tex) {
  float2 xy = worldCoord;
  float2 uvt;
  float d = length(xy);

  //distance of distortion
  if (d < 1.0 && uPower != 0.0)
  {
    //if power is 0, then don't call the distortion function since there's no reason to do it :)
    uvt = Distort(xy, uPower, uSpeed, uFrequency, uni.iTime);
  }
  else
  {
    uvt = textureCoord;
  }
  float4 c = tex.sample(iChannel0, uvt);
  return float4(c.rgb, 1);
}
