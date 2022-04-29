/** 
Author: Txoka
gradient descent
print value from: https://www.shadertoy.com/view/4sBSWW
*/

#define shaderName simple_gradient_descent

#include "Common.h" 

struct KBuffer {
};


// ============================================= common =================================

static float DigitBin( const int x )
{
  return x==0?480599.0:x==1?139810.0:x==2?476951.0:x==3?476999.0:x==4?350020.0:x==5?464711.0:x==6?464727.0:x==7?476228.0:x==8?481111.0:x==9?481095.0:0.0;
}

static float PrintValue( const float2 vStringCoords, const float fValue, const float fMaxDigits, const float fDecimalPlaces )
{
  if ((vStringCoords.y < 0.0) || (vStringCoords.y >= 1.0)) return 0.0;
  float fLog10Value = log2(abs(fValue)) / log2(10.0);
  float fBiggestIndex = max(floor(fLog10Value), 0.0);
  float fDigitIndex = fMaxDigits - floor(vStringCoords.x);
  float fCharBin = 0.0;
  if(fDigitIndex > (-fDecimalPlaces - 1.01)) {
    if(fDigitIndex > fBiggestIndex) {
      if((fValue < 0.0) && (fDigitIndex < (fBiggestIndex+1.5))) fCharBin = 1792.0;
    } else {
      if(fDigitIndex == -1.0) {
        if(fDecimalPlaces > 0.0) fCharBin = 2.0;
      } else {
        float fReducedRangeValue = fValue;
        if(fDigitIndex < 0.0) { fReducedRangeValue = fract( fValue ); fDigitIndex += 1.0; }
        float fDigitValue = (abs(fReducedRangeValue / (pow(10.0, fDigitIndex))));
        fCharBin = DigitBin(int(floor(mod(fDigitValue, 10.0))));
      }
    }
  }
  return floor(mod((fCharBin / pow(2.0, floor(fract(vStringCoords.x) * 4.0) + (floor(vStringCoords.y * 5.0) * 4.0))), 2.0));
}


static float PrintValue(const float2 winCoord, const float2 vPixelCoords, const float2 vFontSize, const float fValue, const float fMaxDigits, const float fDecimalPlaces)
{
  float2 vStringCharCoords = (winCoord - vPixelCoords) / vFontSize;

  return PrintValue( vStringCharCoords, fValue, fMaxDigits, fDecimalPlaces );
}

//https://www.shadertoy.com/view/4sBSWW

// ===========================================================================================


  #define zoom 2.
 #define descendInit 0.
 //#define descendSpeed 1.
 #define descendSpeed 20.


 #define S(v) smoothstep(pixels,0.,v)
static  float f(float x,float2 m){
   return cos(x-m.x)+m.y;
 }
 /*float f(float x,float2 m){
   return -pow(x,1./x);
 }*/

 //n -> e


fragmentFn1() {
  FragmentOutput fff;

    float2 uv2 = thisVertex.where.xy/uni.iResolution.xy;

    fff.fragColor = renderInput[0].sample(iChannel0,uv2);
	
 // ============================================== buffers =============================

    float2 uv = thisVertex.where.xy/uni.iResolution.xy*2.-1.;
	uv.x*=uni.iResolution.x/uni.iResolution.y;
    uv*=zoom;
	float2 mouse = uni.iMouse.xy * 2.-1.;
	mouse.x*=uni.iResolution.x/uni.iResolution.y;
	mouse*=zoom;
    
	float n=renderInput[0].sample(iChannel0,float2(0)).r;
	n-=(f(n+0.01,mouse)-f(n-0.01,mouse))*(descendSpeed);
    
	if(uni.iTime<1.)n=(descendInit);
	
    float pixels=2./uni.iResolution.y*(zoom);
    float3 col = float3(0,0,1)*smoothstep(pixels,0.,abs(f(uv.x,mouse)-uv.y));

    col+=smoothstep(pixels,0.,abs(uv.x-n))*float3(1,0,0);
    col+=0.3*smoothstep(pixels,0.,abs(uv.x));
    col+=0.3*smoothstep(pixels,0.,abs(uv.y));
	col+=0.2*smoothstep(pixels,0.,abs(fract(abs(uv.x)-0.5)-0.5));
    col+=0.2*smoothstep(pixels,0.,abs(fract(abs(uv.y)-0.5)-0.5));
    col+=0.1*smoothstep(pixels,0.,abs(fract(abs(uv.x)*10.-0.5)-0.5)/10.);
    col+=0.1*smoothstep(pixels,0.,abs(fract(abs(uv.y)*10.-0.5)-0.5)/10.);
	
    fff.pass1 = float4(col,1.0);
    fff.pass1+=PrintValue(uv,float2(n,0.9*(zoom)),float2(0.06)*(zoom),abs(n),2.,6.);
	
	fff.pass1.r=distance(thisVertex.where.xy,float2(0))<1.?n:fff.pass1.r;
  return fff;
}
