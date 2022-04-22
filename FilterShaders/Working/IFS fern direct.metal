
#define shaderName ifs_fern_direct

#include "Common.h" 

constant const float2 C = float2( 5.5, 1 );

static float4 I(float2 U, float2x2 M, float2 V, texture2d<float> rendin0) {
  constexpr sampler smp(coord::normalized, address::clamp_to_edge, filter::nearest ); // iChannel2
  return rendin0.sample(smp, ( (U-V) * inverse(M) + C ) / 12. , bias(-15.) );
}

fragmentFn( texture2d<float> lastFrame ) {
  constexpr sampler smp(coord::normalized, address::clamp_to_edge, filter::nearest ); // iChannel2
  
  float2 R = uni.iResolution;
  float2 U = 12. * thisVertex.where.xy/R - C;
  float k = 20.* lastFrame.sample(smp, U, bias(15) ).g;
  
  float4 fragColor = uni.iFrame==0 || uni.wasMouseButtons ? float4( step(length(U+U-1.),1.) )         // seed with a blob
  : max(  lastFrame.sample(smp, thisVertex.where.xy/R )*.9 ,
        max( max( I(U, float2x2( .01, 0    ,0  , .16), float2( 0, 0   ) , lastFrame    ),      // copy to stem ( .01 instead of 0 or degenerated)
                 I(U, float2x2( .85, .04, -.04, .85), float2( 0, 1.6 ) , lastFrame    )   ),  // copy to next row
            max(  I(U, float2x2( .20,-.26,  .23, .22), float2( 0, 1.6 ) , lastFrame    ),      // copy to mirror side
                I(U, float2x2(-.15, .28,  .26, .24), float2( 0,  .4 ) , lastFrame    )   )   // copy to left side
            ) / k );        // note that max( T, ( I1+I2+I3+I4 ) / k' ) also works
  
  return saturate(fragColor);
}
