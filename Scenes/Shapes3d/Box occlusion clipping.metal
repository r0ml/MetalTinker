/** 
Author: iq
Analytic occlusion of triangles, with proper clipping. With clipping, polygons can fall (completely or partially) below the visibility horizon of the receiving point, while still computing analytically correct occlusion. Move mouse to compare.
*/
#define shaderName Box_occlusion_clipping

#include "Common.h"

struct InputBuffer {
};

initialize() {
}

 


// Analytical ambient occlusion of triangles. Left side of screen, stochastically 
// sampled occlusion. Right side of the screen, analytical solution (no rays casted).

// This shader computes proper clipping. With clipping, polygons can fall (completely 
// or partially) below the visibility horizon of the receiving point, while still 
// computing analytically correct occlusion.

// More info here: http://www.iquilezles.org/www/articles/boxocclusion/boxocclusion.htm


// Other shaders with analytical occlusion or approximations:
// 
// Box:                        https://www.shadertoy.com/view/4djXDy
// Box with horizon clipping:  https://www.shadertoy.com/view/4sSXDV
// Triangle:                   https://www.shadertoy.com/view/XdjSDy
// Sphere:                     https://www.shadertoy.com/view/4djSDy
// Ellipsoid (approximation):  https://www.shadertoy.com/view/MlsSzn



//=====================================================

static float sacos( float x ) { return acos( min(max(x,-1.0),1.0) ); }

static float3 clip( const float3 a, const float3 b, const float4 p )
{
    return a - (b-a)*(p.w + dot(p.xyz,a))/dot(p.xyz,(b-a));
//    return ( a*dot(p.xyz,b) - b*dot(p.xyz,a)  - (b-a)*p.w ) / dot(p.xyz,(b-a));
}

//-----------------------------------------------------------------------------------------

// fully visible front facing Triangle occlusion
static float ftriOcclusion( const float3 pos, const float3 nor, const float3 v0, const float3 v1, const float3 v2 )
{
    float3 a = normalize( v0 - pos );
    float3 b = normalize( v1 - pos );
    float3 c = normalize( v2 - pos );

    return (dot( nor, normalize( cross(a,b)) ) * sacos( dot(a,b) ) +
            dot( nor, normalize( cross(b,c)) ) * sacos( dot(b,c) ) +
            dot( nor, normalize( cross(c,a)) ) * sacos( dot(c,a) ) ) / TAU;
}


// fully visible front acing Quad occlusion
static float fquadOcclusion( const float3 pos, const float3 nor, const float3 v0, const float3 v1, const float3 v2, const float3 v3 )
{
    float3 a = normalize( v0 - pos );
    float3 b = normalize( v1 - pos );
    float3 c = normalize( v2 - pos );
    float3 d = normalize( v3 - pos );
    
    return (dot( nor, normalize( cross(a,b)) ) * sacos( dot(a,b) ) +
            dot( nor, normalize( cross(b,c)) ) * sacos( dot(b,c) ) +
            dot( nor, normalize( cross(c,d)) ) * sacos( dot(c,d) ) +
            dot( nor, normalize( cross(d,a)) ) * sacos( dot(d,a) ) ) / TAU;
}

// partially or fully visible, front or back facing Triangle occlusion
static float triOcclusion( const float3 pos, const float3 nor, const float3 v0, const float3 v1, const float3 v2, const float4 plane )
{
    if( dot( v0-pos, cross(v1-v0,v2-v0) ) < 0.0 ) return 0.0;  // back facing
    
    float s0 = dot( float4(v0,1.0), plane );
    float s1 = dot( float4(v1,1.0), plane );
    float s2 = dot( float4(v2,1.0), plane );
    
    float sn = sign(s0) + sign(s1) + sign(s2);

    float3 c0 = clip( v0, v1, plane );
    float3 c1 = clip( v1, v2, plane );
    float3 c2 = clip( v2, v0, plane );
    
    // 3 (all) vertices above horizon
    if( sn>2.0 )  
    {
        return ftriOcclusion(  pos, nor, v0, v1, v2 );
    }
    // 2 vertices above horizon
    else if( sn>0.0 ) 
    {
        float3 pa, pb, pc, pd;
              if( s0<0.0 )  { pa = c0; pb = v1; pc = v2; pd = c2; }
        else  if( s1<0.0 )  { pa = c1; pb = v2; pc = v0; pd = c0; }
        else/*if( s2<0.0 )*/{ pa = c2; pb = v0; pc = v1; pd = c1; }
        return fquadOcclusion( pos, nor, pa, pb, pc, pd );
    }
    // 1 vertex aboce horizon
    else if( sn>-2.0 ) 
    {
        float3 pa, pb, pc;
              if( s0>0.0 )   { pa = c2; pb = v0; pc = c0; }
        else  if( s1>0.0 )   { pa = c0; pb = v1; pc = c1; }
        else/*if( s2>0.0 )*/ { pa = c1; pb = v2; pc = c2; }
        return ftriOcclusion(  pos, nor, pa, pb, pc );
    }
    // zero (no) vertices above horizon
    
    return 0.0;
}


//-----------------------------------------------------------------------------------------


// Box occlusion (if fully visible)
static float boxOcclusion( const float3 pos, const float3 nor, const float4x4 txx, const float4x4 txi, const float3 rad )
{
	float3 p = (txx*float4(pos,1.0)).xyz;
	float3 n = (txx*float4(nor,0.0)).xyz;
    float4 w = float4( n, -dot(n,p) ); // clipping plane
    
    // 8 verts
    float3 v0 = float3(-1.0,-1.0,-1.0)*rad;
    float3 v1 = float3( 1.0,-1.0,-1.0)*rad;
    float3 v2 = float3(-1.0, 1.0,-1.0)*rad;
    float3 v3 = float3( 1.0, 1.0,-1.0)*rad;
    float3 v4 = float3(-1.0,-1.0, 1.0)*rad;
    float3 v5 = float3( 1.0,-1.0, 1.0)*rad;
    float3 v6 = float3(-1.0, 1.0, 1.0)*rad;
    float3 v7 = float3( 1.0, 1.0, 1.0)*rad;
    

    // 6 faces    
    float occ = 0.0;
    occ += triOcclusion( p, n, v0, v2, v3, w );
    occ += triOcclusion( p, n, v0, v3, v1, w );

    occ += triOcclusion( p, n, v4, v5, v7, w );
    occ += triOcclusion( p, n, v4, v7, v6, w );
    
    occ += triOcclusion( p, n, v5, v1, v3, w );
    occ += triOcclusion( p, n, v5, v3, v7, w );
    
    occ += triOcclusion( p, n, v0, v4, v6, w );
    occ += triOcclusion( p, n, v0, v6, v2, w );
    
    occ += triOcclusion( p, n, v6, v7, v3, w );
    occ += triOcclusion( p, n, v6, v3, v2, w );
    
    occ += triOcclusion( p, n, v0, v1, v5, w );
    occ += triOcclusion( p, n, v0, v5, v4, w );

    return occ;
}

//-----------------------------------------------------------------------------------------

// returns t and normal
static float4 boxIntersect( const float3 ro, const float3 rd, const float4x4 txx, const float4x4 txi, const float3 rad )
{
    // convert from ray to box space
	float3 rdd = (txx*float4(rd,0.0)).xyz;
	float3 roo = (txx*float4(ro,1.0)).xyz;

	// ray-box intersection in box space
    float3 m = 1.0/rdd;
    float3 n = m*roo;
    float3 k = abs(m)*rad;
	
    float3 t1 = -n - k;
    float3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
	if( tN > tF || tF < 0.0) return float4(-1.0);

	float3 nor = -sign(rdd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

    // convert to ray space
	
	nor = (txi * float4(nor,0.0)).xyz;

	return float4( tN, nor );
}

static float4x4 rotationAxisAngle( float3 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    float ic = 1.0 - c;

    return float4x4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
			     0.0,                0.0,                0.0,                1.0 );
}

static float4x4 translate( float x, float y, float z )
{
    return float4x4( 1.0, 0.0, 0.0, 0.0,
				 0.0, 1.0, 0.0, 0.0,
				 0.0, 0.0, 1.0, 0.0,
				 x,   y,   z,   1.0 );
}


static float2 hash2( float n ) { return fract(sin(float2(n,n+1.0))*float2(43758.5453123,22578.1459123)); }

//-----------------------------------------------------------------------------------------

static float iPlane( const float3 ro, const float3 rd )
{
    return (-1.0 - ro.y)/rd.y;
}

fragmentFn()
{
	float2 p = worldCoordAspectAdjusted;
  float s = uni.mouseButtons ? (2.0*uni.iMouse.x-1) : 0.0;

	float3 ro = float3(0.0, 0.0, 4.0 );
	float3 rd = normalize( float3(p,-2.0) );
	
    // box animation
	float4x4 rot = rotationAxisAngle( normalize(float3(1.0,0.9,0.5)), 0.5*uni.iTime );
	float4x4 tra = translate( 0.0, 0.0, 0.0 );
	float4x4 txi = tra * rot; 
	float4x4 txx = inverse( txi );
	float3 box = float3(0.2,0.7,2.0) ;

    float3 rrr = interporand((thisVertex.where.xy)/uni.iResolution.xy, 0.0  ).xzy;

    float3 col = float3(0.0);

    float tmin = 1e10;
    
    float t1 = iPlane( ro, rd );
    if( t1>0.0 )
    {
        tmin = t1;
        float3 pos = ro + tmin*rd;
        float3 nor = float3(0.0,1.0,0.0);
        float occ = 0.0;
        
        if( p.x > s )
        {
            occ = boxOcclusion( pos, nor, txx, txi, box );
        }
        else
        {
   		    float3  ru  = normalize( cross( nor, float3(0.0,1.0,1.0) ) );
		    float3  rv  = normalize( cross( ru, nor ) );

            occ = 0.0;
            for( int i=0; i<256; i++ )
            {
                float2  aa = hash2( rrr.x + float(i)*203.1 );
                float ra = sqrt(aa.y);
                float rx = ra*cos(TAU*aa.x);
                float ry = ra*sin(TAU*aa.x);
                float rz = sqrt( 1.0-aa.y );
                float3  dir = float3( rx*ru + ry*rv + rz*nor );
                float4 res = boxIntersect( pos, dir, txx, txi, box );
                occ += step(0.0,res.x);
            }
            occ /= 256.0;
        }

        col = float3(1.2);
        col *= 1.0 - occ;
    }

    float4 res = boxIntersect( ro, rd, txx, txi, box );
    float t2 = res.x;
    if( t2>0.0 && t2<tmin )
    {
        tmin = t2;
       // float t = t2;
       // float3 pos = ro + t*rd;
        float3 nor = res.yzw;
		col = float3(1.4);//float3(1.0,0.85,0.6);
        col *= 0.6 + 0.4*nor.y;
	}

	col *= exp( -0.05*tmin );

    float e = 2.0/uni.iResolution.y;
    col *= smoothstep( 0.0, 2.0*e, abs(p.x-s) );
    
    return float4( col, 1.0 );
}
