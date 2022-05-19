
#define shaderName Portal_2_Box_Flip_Rotation

#include "Common.h"

static float2 plane(float3 p, float3 d, float3 normal)
{
  float3 up = float3(0,1,0);
  float3 right = cross(up, normal);
  
  float dn = dot(d, normal);
  float pn = dot(p, normal);
  
  float3 hit = p - d / dn * pn;
  
  float2 uv;
  uv.x = dot(hit, right);
  uv.y = dot(hit, up);
  
  return uv;
}

fragmentFunc(texture2d<float> tex0, texture2d<float> tex1) {
  float grid_width = 0.1;
  float2 tc = textureCoord;
  float2 xy = tc / grid_width;
  float2 grid = floor(xy);
  xy = mod(xy, 1.0)- 0.5;
  
  float alpha = 0.0;//uni.iMouse.x / uni.iResolution.x;
  float time = scn_frame.time - (grid.y - grid.x)*0.1;
  time = mod(time, 6.0);
  alpha += smoothstep(0.0, 1.0, time);
  alpha += 1.0 - smoothstep(3.0, 4.0, time);
  alpha = abs(mod(alpha, 2.0)-1.0);

  float side = step(0.5, alpha);
  
  alpha = radians(alpha*180.0);
  float4 n = float4(cos(alpha),0,sin(alpha),-sin(alpha));
  float3 d = float3(1.0,xy.y,xy.x);
  float3 p = float3(-1.0+n.w/4.0,0,0);
  float2 uv = plane(p, d, n.xyz);

  uv += 0.5;
  if (uv.x<0.0||uv.y<0.0||uv.x>1.0||uv.y>1.0)
  {
    return 0;
  }

  float2 guv = grid*grid_width;

  float2 c1c = guv + float2(1-uv.x,uv.y)*grid_width;
  float2 c2c = guv + float2(uv.x,1-uv.y)*grid_width;
  float4 c1 = tex0.sample(iChannel0, c1c );
  float4 c2 = tex1.sample(iChannel0, c2c ) ;
  return saturate(mix(c1, c2, side));

  return float4(xy, 0, 1); // float4(uv, guv);
}
