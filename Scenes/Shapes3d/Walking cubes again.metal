
#define shaderName Walking_cubes_again

#include "Common.h"

struct InputBuffer { };
initialize() {}


#define SQRT_2 1.4142135623730951
#define HALF_PI 1.5707963267948966
#define QUARTER_PI 0.7853981633974483

#define CUBE_SIZE 0.5

float2 opU( float2 d1, float2 d2 )
{
    return ( d1.x < d2.x ) ? d1 : d2;
}

float3x3 transform( float a, thread float2& offset )
{
    float c = cos( a );
    float s = sin( a );
    float2 v = CUBE_SIZE * SQRT_2 * abs( float2( cos( a + QUARTER_PI ), sin( a + QUARTER_PI ) ) );
    offset.x = - min( abs( v.x ), abs( v.y ) );
    offset.y = max( v.x, v.y );
    if ( mod( a, HALF_PI ) > QUARTER_PI )
    {
        offset.x = - offset.x;
    }
    float n = floor( a / QUARTER_PI ) + 2.0;
    offset.x += CUBE_SIZE * 2.0 * floor( n / 2.0 );
    offset.x = mod( offset.x, 12.0 ) - 5.0;

    // rotation matrix inverse
    return float3x3( c, 0, s,
                -s, 0, c,
                 0, 1, 0 );
}

float udRoundBoxT( float3 p )
{
    float r = 0.1;
    return length( max( abs( p ) - float3( CUBE_SIZE - r ), 0.0 ) ) - r;
}

float hash( float n )
{
    return fract( sin( n ) * 4121.15393 );
}

float2 map( float3 p, const float iTime )
{
    float2 plane = float2( abs( p.y ), 1.0 );

    float2 offset = float2( 0 );
    float3x3 t = transform( iTime * 2.0, offset );
    float3 q = t * ( p  - float3( offset.x - 0.3, offset.y, -3.0 ) );
    float2 box = float2( udRoundBoxT( q ), 2.0 );

    float3x3 t2 = transform( 4.0 + iTime * 2.5, offset );
    float3 q2 = t2 * ( p  - float3( offset.x + 0.1, offset.y, 1.0 ) );
    float2 box2 = float2( udRoundBoxT( q2 ), 3.0 );

    float3x3 t3 = transform( 2.0 + iTime * 1.2, offset );
    float3 q3 = t3 * ( p  - float3( offset.x + 0.4, offset.y, -1.2 ) );
    float2 box3 = float2( udRoundBoxT( q3 ), 4.0 );

    float3x3 t4 = transform( -1.3 + iTime * 1.75, offset );
    float3 q4 = t4 * ( p  - float3( offset.x + 0.3, offset.y, 2.3 ) );
    float2 box4 = float2( udRoundBoxT( q4 ), 5.0 );

    return opU( opU( box, opU( box2, opU( box3, box4 ) ) ),
                plane );
}

float2 scene( float3 ro, float3 rd, const float iTime )
{
    float t = 0.1;
    for ( int i = 0; i < 64; i++ )
    {
        float3 pos = ro + rd * t;
        float2 res = map( pos, iTime );
        if ( res.x < 0.0005 )
        {
            return float2( t, res.y );
        }
        t += res.x;
    }
    return float2( -1.0 );
}

float calcShadow( float3 ro, float3 rd, float mint, float maxt, const float iTime )
{
    float t = mint;
    float res = 1.0;
    for ( int i = 0; i < 32; i++ )
    {
        float2 h = map( ro + rd * t, iTime );
        res = min( res, 2.0 * h.x / t );
        t += h.x;
        if ( ( h.x < 0.001 ) || ( t > maxt ) )
        {
            break;
        }
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAo( float3 pos, float3 n, const float iTime )
{
    float occ = 0.0;
    for ( int i = 0; i < 5; i++ )
    {
        float hp = 0.01 + 0.1 * float(i) / 4.0;
        float dp = map( pos + n * hp, iTime ).x;
        occ += ( hp - dp );
    }
    return clamp( 1.0 - 1.5 * occ, 0.0, 1.0 );
}

float3 calcNormal( float3 pos, const float iTime )
{
    float3 eps = float3( 0.001, 0.0, 0.0 );
    float3 n = float3(
            map( pos + eps.xyy, iTime ).x - map( pos - eps.xyy, iTime ).x,
            map( pos + eps.yxy, iTime ).x - map( pos - eps.yxy, iTime ).x,
            map( pos + eps.yyx, iTime ).x - map( pos - eps.yyx, iTime ).x );
    return normalize( n );
}

fragmentFn() {
//    float2 uv = ( thisVertex.where.xy - 0.5 * uni.iResolution.xy )/ uni.iResolution.y;
  float2 uv = ndc(thisVertex.where.xy, uni.iResolution) / 2;
  
    float3 eye = float3( 0.0, 7.0, 20.0 );
    float3 target = float3( 0.0 );
    float3 cw = normalize( target - eye );
    float3 cu = cross( cw, float3( 0.0, 1.0, 0.0 ) );
    float3 cv = cross( cu, cw );
    float3x3 cm = float3x3( cu, cv, cw );
    float3 rd = cm * normalize( float3( uv, 6.0 ) );

    float2 res = scene( eye, rd, uni.iTime );

    float3 col = float3( 0.0 );
    if ( res.x >= 0.0 )
    {
        float3 pos = eye + rd * res.x;
        float3 n = calcNormal( pos, uni.iTime );
        if ( res.y == 1.0 )
        {
          col = float3( 0.2 + mod( floor( pos.x ) + floor( pos.z ), 2.0 ) );
        }
        else
        {
            col = palette( ( res.y - 1.0 ) / 4.0,
                     float3( 0.5, 0.5, 0.5 ), float3( 0.5, 0.5, 0.5  ),
                     float3( 1.0, 1.0, 1.0 ), float3( 0.0, 0.33, 0.67 ) );
        }

        float3 ldir = normalize( float3( 0.5, 2.8, 4.0 ) );
        float sh = calcShadow( pos, ldir, 0.01, 4.0, uni.iTime );
        float ao = calcAo( pos, n, uni.iTime );
        col *= ( 0.2 + ao ) * ( 0.3 + sh );

        float3 ref = reflect( rd, n );
        float refSh = calcShadow( pos, ref, 0.01, 4.0, uni.iTime );

        float dif = max( dot( n, ldir ), 0.0 );
        float spe = pow( clamp( dot( ref, ldir ), 0.0, 1.0 ), 15.0 );

        col *= ( 0.3 + dif ) * ( 0.5 + refSh );
        col += dif * sh *  spe * float3( 1.0 );
    }

    return float4( col, 1.0 );
}
