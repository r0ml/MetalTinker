
// trying to resemble watercolors

#define shaderName watercolor

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}

constant const int SampNum = 24;

static float4 getCol(float2 pos, texture2d<float> vid0)
{
  float2 uv=pos/textureSize(vid0);
  float4 c1 = vid0.sample(iChannel0,uv);
  float4 c2 = float4(.4); // gray on greenscreen
  float d = saturate(dot(c1.xyz,float3(-0.5,1.0,-0.5)));
  return mix(c1,c2,1.8*d);
}

static float4 getCol2(float2 pos, texture2d<float> vid0)
{
  float2 uv=pos/textureSize(vid0);
  float4 c1 = vid0.sample(iChannel0,uv);
  float4 c2 = float4(1.5); // bright white on greenscreen
  float d = saturate(dot(c1.xyz,float3(-0.5,1.0,-0.5)));
  return mix(c1,c2,1.8*d);
}

static float2 getGrad(float2 pos,float delta, texture2d<float> vid0)
{
  float2 d=float2(delta,0);
  return float2(
              dot((getCol(pos+d.xy, vid0)-getCol(pos-d.xy, vid0)).xyz,float3(.333)),
              dot((getCol(pos+d.yx, vid0)-getCol(pos-d.yx, vid0)).xyz,float3(.333))
              )/delta;
}

static float2 getGrad2(float2 pos,float delta, texture2d<float> vid0)
{
  float2 d=float2(delta,0);
  return float2(
              dot((getCol2(pos+d.xy, vid0)-getCol2(pos-d.xy, vid0)).xyz,float3(.333)),
              dot((getCol2(pos+d.yx, vid0)-getCol2(pos-d.yx, vid0)).xyz,float3(.333))
              )/delta;
}

static float htPattern(float2 pos) {
  float r=interporand(pos / 256. *.4/.7).x;
  return saturate((pow(r+.3,2.)-.45));
}

static float getVal(float2 pos, float level, texture2d<float> vid0)
{
  return length(getCol(pos, vid0).xyz)+0.0001*length(pos-0.5*textureSize(vid0));
  return dot(getCol(pos, vid0).xyz,float3(.333));
}

static float4 getBWDist(float2 pos, texture2d<float> vid0)
{
  return float4(smoothstep(.9,1.1,getVal(pos,0., vid0)*.9+htPattern(pos*.7)));
}


fragmentFn(texture2d<float> tex0) {
  float2 pos=((thisVertex.where.xy-uni.iResolution.xy*.5)/uni.iResolution.y*textureSize(tex0).y)+textureSize(tex0).xy*.5;
  float2 pos2=pos;
  float2 pos3=pos;
  float2 pos4=pos;
  float2 pos0=pos;
  float3 col=float3(0);
  float3 col2=float3(0);
  float cnt=0.0;
  float cnt2=0.;
  for(int i=0;i<1*SampNum;i++)
  {   
    // gradient for outlines (gray on green screen)
    float2 gr =getGrad(pos, 2.0, tex0)+.0001*(interporand(pos / 256. ).xy-.5);
    float2 gr2=getGrad(pos2,2.0, tex0)+.0001*(interporand(pos2 / 256. ).xy-.5);
    
    // gradient for wash effect (white on green screen)
    float2 gr3=getGrad2(pos3,2.0, tex0)+.0001*(interporand(pos3 / 256.).xy-.5);
    float2 gr4=getGrad2(pos4,2.0, tex0)+.0001*(interporand(pos4 / 256.).xy-.5);
    
    float grl=saturate(10.*length(gr));
    float gr2l=saturate(10.*length(gr2));
    
    // outlines:
    // stroke perpendicular to gradient
    pos +=.8 *normalize( gr.yx * float2(1, -1)  );
    pos2-=.8 *normalize( gr2.yx * float2(1, -1) );
    float fact=1.-float(i)/float(SampNum);
    col+=fact*mix(float3(1.2),getBWDist(pos, tex0).xyz*2.,grl);
    col+=fact*mix(float3(1.2),getBWDist(pos2, tex0).xyz*2.,gr2l);
    
    // colors + wash effect on gradients:
    // color gets lost from dark areas
    pos3+=.25*normalize(gr3)+.5*(interporand(pos0 / 256. *.07).xy-.5);
    // to bright areas
    pos4-=.5 *normalize(gr4)+.5*(interporand(pos0 / 256. *.07).xy-.5);

    float f1=3.*fact;
    float f2=4.*(.7-fact); 
    col2+=f1*(getCol2(pos3, tex0).xyz+.25+.4* interporand(pos3 / 256.).xyz);
    col2+=f2*(getCol2(pos4, tex0).xyz+.25+.4* interporand(pos4 / 256.).xyz);
    
    cnt2+=f1+f2;
    cnt+=fact;
  }
  // normalize
  col/=cnt*2.5;
  col2/=cnt2*1.65;
  
  // outline + color
  col = saturate( saturate(col*.9+.1 ) * col2);
  // paper color and grain
  col = col*float3(.93,0.93,0.85)
  *mix(tex0.sample(iChannel0,thisVertex.where.xy.xy/uni.iResolution.xy).xyz,float3(1.2),.7)
  +.15*interporand(pos0 / 256. *2.5).x;
  // vignetting
  float r = length((thisVertex.where.xy-uni.iResolution.xy*.5)/uni.iResolution.x);
  float vign = 1.-r*r*r*r;
  
  return float4(col*vign,1.0);
}

