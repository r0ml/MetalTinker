/** 
 "Attempt at a procedurally generated blue noise mask"
 to experiment and understand it.
 */
#define shaderName Blue_Noise_Stippling_2

#include "Common.h"

struct InputBuffer {
};

initialize() {
}


// simplified version of joeedh's https://www.shadertoy.com/view/Md3GWf
// see also https://www.shadertoy.com/view/MdtGD7

// --- checkerboard noise : to decorelate the pattern between size x size tiles 

// simple x-y decorrelated noise seems enough
#define stepnoise0(p, size) rnd( floor(p/size)*size ) 
#define rnd(U) fract(sin( 1e3*(U)*float2x2(1,-7.131, 12.9898, 1.233) )* 43758.5453)

//   joeedh's original noise (cleaned-up)
/*static float2 stepnoise(float2 p, float size) {
  p = floor((p+10.)/size)*size;          // is p+10. useful ?
  p = fract(p*.1) + 1. + p*float2(2,3)/1e4;
  p = fract( 1e5 / (.1*p.x*(p.y+float2(0,1)) + 1.) );
  p = fract( 1e5 / (p*float2(.1234,2.35) + 1.) );
  return p;
}*/

// --- stippling mask  : regular stippling + per-tile random offset + tone-mapping
static float mask(float2 p) { 
#define SEED1 1.705
#define DMUL  8.12235325       // are exact DMUL and -.5 important ?
  p += ( stepnoise0(p, 5.5) - .5 ) *DMUL;   // bias [-2,2] per tile otherwise too regular
  float f = fract( p.x*SEED1 + p.y/(SEED1+.15555) ); //  weights: 1.705 , 0.5375
                                                     //return f;  // If you want to skeep the tone mapping
  f *= 1.03; //  to avoid zero-stipple in plain white ?
             // --- indeed, is a tone mapping ( equivalent to do the reciprocal on the image, see tests )
             // returned value in [0,37.2] , but < 0.57 with P=50%
  return  (pow(f, 150.) + 1.3*f ) / 2.3; // <.98 : ~ f/2, P=50%  >.98 : ~f^150, P=50%
}                                          // max = 37.2, int = 0.55

// --- for ramp at screen bottom 
#define tent(f) ( 1. - abs(2.*fract(f)-1.) )
// --- fetch luminance( texture (pixel + offset) )
#define s(x,y) dot( tex.sample(iChannel0, (thisVertex.where.xy+float2(x,y))/R ), float4(.3,.6,.1,0) ) // luminance

fragmentFn(texture2d<float> tex) {
  float2 R = uni.iResolution.xy;
  // --- fetch texture luminance and enhance the contrast
  float f =  s(-1,-1) + s(-1,0) + s(-1,1)
  + s( 0,-1) +         + s( 0,1)
  + s( 1,-1) + s( 1,0) + s( 1,1),
  f0 = s(0,0);
  f = ( .5*f + 2.*f0 ) / 6.;
  
  f = f0 - ( f-f0 ) * 40.;
  
  // --- stippling
  float4 fragColor = 0;
  fragColor += step(mask(thisVertex.where.xy), thisVertex.where.y/R.x < .05 ? tent(thisVertex.where.x/R.x*.5) : f);
  //f = f<.565 ? f/.565 : pow((f-.565)/.434,1./150.); // tone map (reciprocal of mask's)
  //O += f0;                        // original texture
  //O += f;                         // contrast enhanced texture
  //O += tent(U.x/R.x*.5);          // gradient
  //O += mask(U);                   // test mask alone
  //O = float4(stepnoise(U, 1.),0,0); // test stepnoise alone
  //O = float4(stepnoise0(U, 1.).x > .5);
  return fragColor;
}
