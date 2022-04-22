
#define shaderName Blue_Feedback

#include "Common.h" 

static float3 rotsim(float2 p,float s){
  float2 ret=p;
  ret=p * rot2d(-PI/(s*2.0));
  float pa=floor(atan2(ret.x,ret.y)/PI*s)*(PI/s);
  ret=p * rot2d(pa);
  return float3(ret.x,ret.y,pa);
}

static float drawPoint(float2 uv){
  return max(1.0-length(uv)*192.0,0.0);
}

fragmentFn(texture2d<float> lastFrame) {

  float2 uv=uni.iResolution.xy;
  float2 winCoord = thisVertex.where.xy;
  uv=-.5*(uv-2.0*winCoord)/uv.x;
  
  //draw points
  uv=uv * rot2d(uni.iTime);
  float3 rs=rotsim(uv,16.0);
  uv=rs.xy;
  float fr=drawPoint(uv-float2(0,0.08+sin(rs.z*19.0+uni.iTime*6.0)*0.03));
  float3 dots = fr * float3(0.5, 1.3, 3.0);
  
  //draw lastframe
  uv= winCoord/uni.iResolution.xy-0.5;
  uv*=0.8+sin(uni.iTime*0.2)*0.2;
  uv+=0.5;
  float3 back=lastFrame.sample(iChannel0,uv).xyz;
  
  //mix lastframe + points
  return float4(back*0.8+dots,1.0);
}
