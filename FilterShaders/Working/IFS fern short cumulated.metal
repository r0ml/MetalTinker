
#define shaderName ifs_fern_short_cumulated

#include "Common.h" 

fragmentFn( texture2d<float> lastFrame ) {
  float2 R = uni.iResolution;
  float2 U = 12. * thisVertex.where.xy/R - float2(5.5,1);
  float2 z = U;
  float4 fragColor = lastFrame.read(uint2(thisVertex.where.xy)) * (uni.iFrame);
  for( float p, i=0.; i<3e2; i++ ) {
    p = fract( 1e4* sin( U.x*73.+U.y*7. + uni.iTime + i ) );
    z = float3(z,1)* ( p < .01 ? float2x3( 0,0,0,0 , .16, 0   )
                      : p < .84 ? float2x3( .85, .04, 0, -.04, .85, 1.6 )
                      : p < .92 ? float2x3( .20,-.26, 0,  .23, .22, 1.6 )
                      :           float2x3(-.15, .28, 0,  .26, .24,  .4 ) );
    if ( i>32.) { fragColor += .002 / dot(U-z,U-z); }
  }
  return fragColor / (uni.iFrame + 1);
}
