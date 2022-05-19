
#define shaderName halftone_lines_2

#include "Common.h" 

#define AngNum 6
//#define AngNum 2   /* only horizontal and vertical */
//#define AngNum 4   /* horizontal, vertical, and 2 x diagonal */

static float4 getCol(float2 uv, texture2d<float> vid0)
{
  float4 e=smoothstep(float4(-0.05),float4(-0.0),float4(uv,float2(1)-uv));
  float mask=e.x*e.y*e.z*e.w;
  return vid0.sample(iChannel0,uv)*mask;
}

float4 getRand(float2 pos)
{
  return rand(pos);
}

static float htPattern(float2 pos, float2 mouse, texture2d<float> vid0)
{
  float p;
  float s = .5+2.*mouse.x;
  if (mouse.x==0.) s=2.5;
  float b=dot(getCol(pos, vid0).xyz*s,float3(.333));
  // float b0=b;
  b=floor(b*float(AngNum));
  p=1.;
  float d=1.-.5+mouse.y;
  if (mouse.y==0.) d=1.;
  for(int i=0;i<AngNum;i++)
  {
    if(float(AngNum-i-1)<b) break;
    float ang=-(float(i)+.0)/float(AngNum)*PI;
    float2 dir = float2(cos(ang),sin(ang));

    float s=sin(dot(dir,pos+getRand(pos).xy*0.)*d /* /(1080./reso.y) */ );
    p-=.7*exp(-s*s*10.);
    d*=1.2;
  }
  return p;
}

fragmentFunc(texture2d<float> tex, constant float2& mouse) {
  float2 pos=textureCoord;
  float hp = htPattern(pos, mouse, tex);
  //fragColor.xy = iChannelResolution[0].xy+float2(.3);
  //fragColor = float4(getCol(pos));
  //fragColor = texture(iChannel0,thisVertex.where.xy/uni.iResolution.xy)+float4(0.3,0,0,1);
  //fragColor = float4(0.3,0,0,1);
  return float4(hp, hp, hp, 1);
}
