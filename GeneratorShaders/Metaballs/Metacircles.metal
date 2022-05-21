
#define shaderName metacircles

#include "Common.h" 

constant const float force = 0.001;

constant const bool bDebug = false;

static float length2(float2 d){ return dot(d,d);}
static float metaball(float2 fragcoord, float2 pos,float f) {
  return f/length2((fragcoord - pos));
}

fragmentFunc() {
  // float2 uv = thisVertex.where.xy.xy / uni.iResolution.xy;
  float t = scn_frame.time;
  float2 uv = textureCoord * nodeAspect;
  float2 middle = 0.5 * nodeAspect;
  float2 r = (90.0 + sin(t)*25.0) * scn_frame.inverseResolution;
  float b = metaball(uv, float2( middle.x + cos(t) * r.x, middle.y + sin(t) * r.y),force);
  
  b += metaball(uv, middle,force);
  
  b -= metaball(uv,float2(0.07,0),4.0*force);
  b -= metaball(uv,middle + float2(0.07,0),force*2.0);
  float4 c = float4(0);
  if( b < 0.8)
    c = float4(1.0*abs(b*b*b),1.0*abs(b*b*b),abs(b)*0.2,1);
  else
    c = float4(0.2*b,0.2*b,b,1.0);
  
  float4 fragColor = c;
  if(bDebug)
    fragColor = float4(abs(b),b,b,1.0);
  return fragColor;
}
