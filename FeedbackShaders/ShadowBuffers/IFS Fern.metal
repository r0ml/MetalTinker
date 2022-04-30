
#define shaderName ifs_fern
#define SHADOWS 2

#include "Common.h" 


/*float hash( float n )
{
    return fract(sin(n)*987.654321);
}*/

 
fragmentFn() {
  FragmentOutput fff;


    float2 uv = thisVertex.where.xy/uni.iResolution.xy;
    
    float4 data = lastFrame[1].read(uint2(thisVertex.where.xy) );
    
    float f = data.x;
    float e2 = data.y / data.z;
    
    float3 col = float3(1.0-f) * (1.0-float3(0.2,0.3,0.6)*e2);
    
    col *= 0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.2 );
    
    fff.color0 = float4( col, 1.0 );


  if( uni.iFrame==0 ) {
    data = float4(0.0);
  }
    
    uv = uv*12.0 - float2(5.5,0.8);
    
    float px = 12.0/uni.iResolution.x;
    
    float2 z = uv;
    
    float p = rand(uni.iTime + thisVertex.where.x*113.1 + thisVertex.where.y*7.3 );
    
    float d = data.x;
    float e3 = data.y;
    for( int i=0; i<256; i++ ) {
        // generate a random number (this should be uniform, but ....)
        p = fract( p + cos(p*6283.1) );
            
             if( p < 0.01 ) z = float2(  0.0, 0.16*z.y );
        else if( p < 0.84 ) z = float2(  0.85*z.x + 0.04*z.y, -0.04*z.x + 0.85*z.y + 1.60 );
        else if( p < 0.92 ) z = float2(  0.20*z.x - 0.26*z.y,  0.23*z.x + 0.22*z.y + 1.60 );
        else                z = float2( -0.15*z.x + 0.28*z.y,  0.26*z.x + 0.24*z.y + 0.44 );
            
        if( i<32 ) continue;
            
        float r = length(uv-z);
        d  = max( d, 1.0-smoothstep( 0.5*px, 1.0*px, r ) );
        e3 += exp(-100.0*r*r);
    }
    
    fff.color1 = float4( d, e3, data.z + 1.0, 1 );
  return fff;
}
