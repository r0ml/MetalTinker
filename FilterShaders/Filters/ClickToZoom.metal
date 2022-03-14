
#define shaderName clicktozoom

#include "Common.h" 

struct InputBuffer {
    struct {
      int _0; // no distortions
      int _1; // distortion
      int _2; // glass ball
    } mode;
};

initialize() {
  in.mode._1 = 1;
}

fragmentFn(texture2d<float> tex) {
  int zoomDistortionMode = in.mode._0 == 1 ? 0 : in.mode._1 == 1 ? 1 : 2;
  
  float2 uv = textureCoord;
  
  float2 center = uni.iMouse.xy;
  
  float2 center2 = center * aspectRatio;
  float2 uv2 = uv * aspectRatio;

  if (distance(uv2, center2) < 0.3) {
    uv -= center;
    if (zoomDistortionMode == 0) {
      uv /= 2.0; // simple zoom
    } else if (zoomDistortionMode == 1) {
      uv *= 0.5*(1.0-pow(abs(uv.x/0.3),2.5));
    } else if (zoomDistortionMode == 2) {
      uv/=0.3; // range from -1 to 1
      uv.x = 3.0 * uv.x * abs(uv.x);
      uv.y = 3.0 * uv.y * abs(uv.y);
      uv*=0.3;
    } else if (zoomDistortionMode == 2) {
      uv/=0.3; // range from -1 to 1
      uv.x = 3.0 * uv.x * abs(uv.x);
      uv.y = 3.0 * uv.y * abs(uv.y);
      uv*=0.3;
    } else if (zoomDistortionMode == 3) {
      uv/=0.3; // range from -1 to 1
      uv.x = 4.0 * pow(abs(uv.x), 3.0);
      uv.y = 4.0 * pow(abs(uv.y), 3.0);
      uv*=0.3;
    }
    uv += center;
  }
  
  uv.x /= 6.0; // 6 cats
  
  return float4(tex.sample(iChannel0, uv).rgb, 1);
}
