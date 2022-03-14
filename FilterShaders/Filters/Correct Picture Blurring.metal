
#define shaderName Correct_Picture_Blurring

#include "Common.h"

struct InputBuffer {
};

initialize() {
}


// The correct way to do blurring, convolution or downsampling for PICTURES is to 
// apply the gamma/degamma before the linear operations. Of course most people do
// not apply the pow() for performanc reasons, but that is wrong:
//
// Notice how the image gets darker when the averaging is done with the raw pixel
// values. However, when degammaing the colors prior to accumulation and applying
// gamma after normalization, the image has no lose in brightness.
//
// Basically if x is your input picture, T your blurring/convolution/filter and y 
// you resulting image, instead of doing
//
// y = T( x )
// 
// you should do 
//
// y = G( T(G^-1(x)) )
//
// where G(x) is the expected gamma function (usually G(x) = x^2.2)
//
// More info here: http://iquilezles.org/www/articles/gamma/gamma.htm

fragmentFn(texture2d<float> tex) {
  // image downsampling/blurring/averaging
  float3 totWrong = 0.0;
  float3 totCorrect = 0.0;
  float2 b = textureCoord;
  for( int j=0; j<9; j++ ) {
    for( int i=0; i<9; i++ ) {
      float2 st = b + (float2(float(i-4),float(j-4)) ) /uni.iResolution.xy;
      float3 co = tex.sample( iChannel0, st).xyz;
      
      totWrong   += co;                // what most people do (incorrect)
      totCorrect += pow(co,float3(2.2)); // what you should do
    }
  }
  
  float3 colWrong   = totWrong / 81.0;                    // what most people do (incorrect)
  float3 colCorrect = gammaEncode(totCorrect/81.0); // what you should do
  
  
  // ------------------------------------------------------------
  
  // reference/original image
  float3 colReference = tex.sample( iChannel0, b ).xyz;
  
  // final image
  float th = 0.1 + 0.8*smoothstep(-0.1,0.1,sin(0.25*TAU*uni.iTime) );
  float3 col = mix( (b.y>th)?colWrong:colCorrect, colReference, smoothstep( -0.1, 0.1, sinpi(uni.iTime) ) );
  col *= smoothstep( 0.005, 0.006, abs(b.y-th) );
  
  return float4( col, 1.0 );
}
