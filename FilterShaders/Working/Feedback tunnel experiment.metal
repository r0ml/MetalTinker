
#define shaderName feedback_tunnel_experiment

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {
  float2 uv = thisVertex.where.xy / uni.iResolution.xy * 2.0 - 1.0;
  uv.x *= uni.iResolution.x / uni.iResolution.y;
  uv.x += sin(uv.y*10.0 + uni.iTime*2.135)/100.0;
  uv *= rot2d(uni.iTime/20.0);
  float2 uv_b = uv*0.9;
  uv_b += sin(uv*10.0 + uni.iTime)/10.0;
  float4 col;
  if(length(uv_b) < 0.6) {
    float2 coord = uv;
    coord *= 1.09 + sin(uni.iTime*2.0)*0.01;
    coord.x /= uni.iResolution.x / uni.iResolution.y;
    coord = (coord + 1.0)/2.0;
    // maybe level instead of bias?
    col = lastFrame.sample(iChannel0, coord, level(0.1) )+0.01;
    col.xy = col.xy * rot2d(-1.8);
    col.yz = col.yz * rot2d( 0.3);
    col.zx = col.zx * rot2d(-1.6);
    col = pow(abs(col),float4(1.001));
  } else {
    col = float4(pow(abs(length(uv_b)-0.61),0.1));
    col *= float4(0.5,1.0,0.2,1.0);
  }

  if (uni.wasMouseButtons) {
    col *= clamp(distance(uni.iMouse.xy * uni.iResolution,thisVertex.where.xy)-0.04*uni.iResolution.y,0.01,1.0);
  }
  return col;
}
