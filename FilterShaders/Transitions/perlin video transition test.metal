
#define shaderName perlin_video_transition_test

#include "Common.h" 

constant const float3x3 m = float3x3( 0.00,  0.80,  0.60,
                                     -0.80,  0.36, -0.48,
                                     -0.60, -0.48,  0.64 );

static float myfbm( float3 p )
{
  float f;
  f  = 0.5000*noisePerlin( p ); p = m*p*2.02;
  f += 0.2500*noisePerlin( p ); p = m*p*2.03;
  f += 0.1250*noisePerlin( p ); p = m*p*2.01;
  f += 0.0625*noisePerlin( p ); p = m*p*2.04;
  f += 0.0625/2.*noisePerlin( p ); p = m*p*2.03;
  f += 0.0625/4.*noisePerlin( p );
  return f;
}

// --- sliders and mouse widgets

static bool affMouse(float2 FragCoord, float2 reso, float2 mouse, Uniform in, thread float4& FragColor)
{
  float R=5.;
  float2 pix = FragCoord.xy/reso.y;
  float pt = max(1e-2,1./reso.y); R*=pt;

  float2 ptr = mouse;
  float2 val = in.lastTouch;
  float s=sign(val.x); val = val*s;

  // current mouse pos
  float k = dot(ptr-pix,ptr-pix)/(R*R*.4*.4);
  if (k<1.)
  { if (k>.8*.8) FragColor = float4(0.);
  else      FragColor = float4(s,.4,0.,1.);
    return true;
  }

  // prev mouse pos
  k = dot(val-pix,val-pix)/(R*R*.4*.4);
  if (k<1.)
  { if (k>.8*.8) FragColor = float4(0.);
  else      FragColor = float4(0.,.2,s,1.);
    return true;
  }

  return false;
}
static bool affSlider(float2 p0, float2 dp, float v, float2 winCoord, float2 reso, thread float4& FragColor)
{
  float R=5.;
  float2 pix = winCoord/reso.y;
  float pt = max(1e-2,1./reso.y); R*=pt;
  pix -= p0;

  float dp2 = dot(dp,dp);
  float x = dot(pix,dp)/dp2; if ((x<0.)||(x>1.)) return false;
  float x2=x*x;
  float y = dot(pix,pix)/dp2-x2; if (y>R*R) return false;

  FragColor = float4(1.,.2,0.,1.);
  y = sqrt(y);
  if (y<pt) return true;       // rule
  float2 p = float2(x-v,y);
  if (dot(p,p)<R*R) return true; // button

  return false;
}


fragmentFn(texture2d<float> tex0, texture2d<float> tex1) {
  float2 FragCoord;
  float4 FragColor = 0;
  FragCoord=thisVertex.where.xy;
  // --- events

  float2 uv  = textureCoord;
  float2 val = uni.iMouse.xy;

  if (affMouse(FragCoord, uni.iResolution, uni.iMouse, uni, FragColor)) return FragColor;
//  if (!uni.mouseButtons) // auto-tuning if no user tuning
//  {
    float t = uni.iTime;
    val = float2(.95,.5) + float2(.04,.3)*float2(cos(t),sin(t));
//  }
  if (affSlider(float2(.05,.02),float2(.4,0),val.x, FragCoord, uni.iResolution, FragColor)) {return FragColor;}
  if (affSlider(float2(.02,.05),float2(0,.4),val.y, FragCoord, uni.iResolution, FragColor)) {return FragColor;}

  // --- shaping noise

  float3 dir = float3(0.,0.,1.);
  float3 p = 4.*float3(uv,0)+uni.iTime*dir;
  float x = myfbm(p);
  // float x1=x;
  // shape 2 ou 3 regions separated by noisy borders
  //x = sin(8.*PI*(x-.5));
  x  = smoothstep(-val.y+val.x,1.-val.y+1.-val.x,x);

  // --- texture and color sources

  uv = mod(uv,float2(1.,1.));
  float3 T0 = tex0.sample(iChannel0,uv).rgb;
  float3 T1 = tex1.sample(iChannel0,uv).rgb;
  //  float3 T2 = texture[0].sample(iChannel0,uv).rgb;
  // float3 B  = float3(0.);
  // float3 W  = float3(1.);
  float3 fire = float3(.6,0.,0.);

  // --- compositing
  float3 v;
  // v = float3(x);
  v = mix(T0,T1,x);
  //v = mix(T0,B,x1)+mix(B,T1,x2-x1)+mix(B,T2,x2);
  float k = (1.-pow(.5+.5*cos(PI*(x-.5)),3.));
  float3 v2;
  // v2 = T2;
  v2 = fire;
  v = mix(v2,v,k);

  return float4(v,1.0);
}

