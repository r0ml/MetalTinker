/** 
Author: iq
Analytic ambient occlusion of a box. Left side of screen, sampled occlusion. Right side of the screen, analytic solution (no rays casted). Move the mouse to compare. Info: [url]http://www.iquilezles.org/www/articles/boxocclusion/boxocclusion.htm[/url]
*/
#define shaderName Box_occlusion

#include "Common.h"

struct InputBuffer {
};

initialize() {
}

 


// Analytical ambient occlusion of a box. Left side of screen, stochastically 
// sampled occlusion. Right side of the screen, analytical solution (no rays casted).
//
// If the box was intersecting the ground plane, we'd need to perform clipping
// and use the resulting triangles for the analytic formula instead.
//    
// More info here: http://www.iquilezles.org/www/articles/boxocclusion/boxocclusion.htm
//
// Other shaders with analytical occlusion or approximations:
// 
// Box:                        https://www.shadertoy.com/view/4djXDy
// Box with horizon clipping:  https://www.shadertoy.com/view/4sSXDV
// Triangle:                   https://www.shadertoy.com/view/XdjSDy
// Sphere:                     https://www.shadertoy.com/view/4djSDy
// Ellipsoid (approximation):  https://www.shadertoy.com/view/MlsSzn
// Capsule (approximation):    https://www.shadertoy.com/view/llGyzG


//=====================================================

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


// Box occlusion (if fully visible)
static float boxOcclusion( const float3 pos, const float3 nor, const float4x4 txx, const float4x4 txi, const float3 rad )
{
	float3 p = (txx*float4(pos,1.0)).xyz;
	float3 n = (txx*float4(nor,0.0)).xyz;
    
    // 8 verts
    float3 v0 = normalize( float3(-1.0,-1.0,-1.0)*rad - p);
    float3 v1 = normalize( float3( 1.0,-1.0,-1.0)*rad - p);
    float3 v2 = normalize( float3(-1.0, 1.0,-1.0)*rad - p);
    float3 v3 = normalize( float3( 1.0, 1.0,-1.0)*rad - p);
    float3 v4 = normalize( float3(-1.0,-1.0, 1.0)*rad - p);
    float3 v5 = normalize( float3( 1.0,-1.0, 1.0)*rad - p);
    float3 v6 = normalize( float3(-1.0, 1.0, 1.0)*rad - p);
    float3 v7 = normalize( float3( 1.0, 1.0, 1.0)*rad - p);
    
    // 12 edges    
    float k02 = dot( n, normalize( cross(v2,v0)) ) * acos( dot(v0,v2) );
    float k23 = dot( n, normalize( cross(v3,v2)) ) * acos( dot(v2,v3) );
    float k31 = dot( n, normalize( cross(v1,v3)) ) * acos( dot(v3,v1) );
    float k10 = dot( n, normalize( cross(v0,v1)) ) * acos( dot(v1,v0) );
    float k45 = dot( n, normalize( cross(v5,v4)) ) * acos( dot(v4,v5) );
    float k57 = dot( n, normalize( cross(v7,v5)) ) * acos( dot(v5,v7) );
    float k76 = dot( n, normalize( cross(v6,v7)) ) * acos( dot(v7,v6) );
    float k37 = dot( n, normalize( cross(v7,v3)) ) * acos( dot(v3,v7) );
    float k64 = dot( n, normalize( cross(v4,v6)) ) * acos( dot(v6,v4) );
    float k51 = dot( n, normalize( cross(v1,v5)) ) * acos( dot(v5,v1) );
    float k04 = dot( n, normalize( cross(v4,v0)) ) * acos( dot(v0,v4) );
    float k62 = dot( n, normalize( cross(v2,v6)) ) * acos( dot(v6,v2) );
    
    // 6 faces    
    float occ = 0.0;
    occ += ( k02 + k23 + k31 + k10) * step( 0.0,  v0.z );
    occ += ( k45 + k57 + k76 + k64) * step( 0.0, -v4.z );
    occ += ( k51 - k31 + k37 - k57) * step( 0.0, -v5.x );
    occ += ( k04 - k64 + k62 - k02) * step( 0.0,  v0.x );
    occ += (-k76 - k37 - k23 - k62) * step( 0.0, -v6.y );
    occ += (-k10 - k51 - k45 - k04) * step( 0.0,  v0.y );
        
    return occ / TAU;
}

//-----------------------------------------------------------------------------------------

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
  float s = uni.mouseButtons ? (2.0*uni.iMouse.x-1) : 0;

	float3 ro = float3(0.0, 0.0, 4.0 );
	float3 rd = normalize( float3(p.x, p.y-0.3,-3.5) );
	
    // box animation
	float4x4 rot = rotationAxisAngle( normalize(float3(1.0,1.0,0.0)), uni.iTime );
	float4x4 tra = translate( 0.0, 0.0, 0.0 );
	float4x4 txi = tra * rot; 
	float4x4 txx = inverse( txi );
	float3 box = float3(0.2,0.5,0.6) ;

    float3 rrr = interporand(thisVertex.where.xy/uni.iResolution.xy  );

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
            for( int i=0; i<512; i++ )
            {
                // cosine distribution
                float2  aa = hash2( rrr.x + float(i)*203.111 );
                float ra = sqrt(aa.y);
                float rx = ra*cos(TAU*aa.x);
                float ry = ra*sin(TAU*aa.x);
                float rz = sqrt( 1.0-aa.y );
                float3  dir = float3( rx*ru + ry*rv + rz*nor );
                float4 res = boxIntersect( pos+nor*0.001, dir, txx, txi, box );
                occ += step(0.0,res.x);
            }
            occ /= 512.0;
        }

        col = float3(1.1);
        col *= 1.0 - occ;
    }

    float4 res = boxIntersect( ro, rd, txx, txi, box );
    float t2 = res.x;
    if( t2>0.0 && t2<tmin )
    {
        tmin = t2;
//        float t = t2;
//        float3 pos = ro + t*rd;
        float3 nor = res.yzw;
		col = float3(0.8);

//		float3 opos = (txx*float4(pos,1.0)).xyz;
//		float3 onor = (txx*float4(nor,0.0)).xyz;
//		col *= abs(onor.x)*texture( iChannel1, 0.5+0.5*opos.yz ).xyz + 
  //             abs(onor.y)*texture( iChannel1, 0.5+0.5*opos.zx ).xyz + 
    //           abs(onor.z)*texture( iChannel1, 0.5+0.5*opos.xy ).xyz;
        col *= 1.7;
        col *= 0.6 + 0.4*nor.y;
	}

	col *= exp( -0.05*tmin );

    float e = 2.0/uni.iResolution.y;
    col *= smoothstep( 0.0, 2.0*e, abs(p.x-s) );
    
    return float4( col, 1.0 );
}

 // ============================================== buffers ============================= 

 
