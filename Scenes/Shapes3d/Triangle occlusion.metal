/** 
 Author: iq
 Analytical ambient occlusion of a triangle. Left side of screen, stochastically sampled occlusion. Right side of the screen, analytical solution (no rays casted). Move the mouse to compare.
 */

// Analytical ambient occlusion of a triangle. Left side of screen, stochastically 
// sampled occlusion. Right side of the screen, analytical solution (no rays casted).
//
// If the polygons was intersecting the ground plane, we'd need to perform clipping
// and use the resulting triangles for the analytic formula instead.


// Other shaders with analytical occlusion or approximations:
// 
// Box:                        https://www.shadertoy.com/view/4djXDy
// Box with horizon clipping:  https://www.shadertoy.com/view/4sSXDV
// Triangle:                   https://www.shadertoy.com/view/XdjSDy
// Sphere:                     https://www.shadertoy.com/view/4djSDy
// Ellipsoid (approximation):  https://www.shadertoy.com/view/MlsSzn
// Capsule (approximation):    https://www.shadertoy.com/view/llGyzG


//=====================================================

#define shaderName triangle_occlusion

#include "Common.h" 

struct InputBuffer {
};

initialize() {
  // setTex(0, asset::arid_mud);
}




// Triangle intersection. Returns { t, u, v }
static float3 triIntersect( float3 ro, float3 rd, float3 v0, float3 v1, float3 v2 )
{
  float3 a = v0 - v1;
  float3 b = v2 - v0;
  float3 p = v0 - ro;
  float3 n = cross( b, a );
  float3 q = cross( p, rd );
  
  float idet = 1.0/dot( rd, n );
  
  float u = dot( q, b )*idet;
  float v = dot( q, a )*idet;
  float t = dot( n, p )*idet;
  
  if( u<0.0 || u>1.0 || v<0.0 || (u+v)>1.0 ) t = -1.0;
  
  return float3( t, u, v );
}

// Triangle occlusion (if fully visible)
static float triOcclusion( float3 pos, float3 nor, float3 v0, float3 v1, float3 v2 )
{
  float3 a = normalize( v0 - pos );
  float3 b = normalize( v1 - pos );
  float3 c = normalize( v2 - pos );
  
  float s = sign(dot(v0-pos,cross(v1-v0,v2-v1))); // side of the triangle
  
  return s*(dot( nor, normalize( cross(a,b)) ) * acos( dot(a,b) ) +
            dot( nor, normalize( cross(b,c)) ) * acos( dot(b,c) ) +
            dot( nor, normalize( cross(c,a)) ) * acos( dot(c,a) ) ) / tau;
}

//=====================================================

static float2 hash2( float n ) { return fract(sin(float2(n,n+1.0))*float2(43758.5453123,22578.1459123)); }

static float iPlane( float3 ro, float3 rd )
{
  return (-1.0 - ro.y)/rd.y;
}

fragmentFn(texture2d<float> tex) {
  float2 p = worldCoordAspectAdjusted;
  float s = uni.mouseButtons ? (2.0*uni.iMouse.x-1) : 0;
  
  float3 ro = float3(0.0, 0.0, 4.0 );
  float3 rd = normalize( float3(p,-2.0) );
  
  // triangle animation
  float3 v1 = cos( uni.iTime + float3(2.0,1.0,1.0) + 0.0 )*float3(1.5,1.0,1.0);
  float3 v2 = cos( uni.iTime + float3(5.0,2.0,3.0) + 2.0 )*float3(1.5,1.0,1.0);
  float3 v3 = cos( uni.iTime + float3(1.0,3.0,5.0) + 4.0 )*float3(1.5,1.0,1.0);
  
  float3 rrr = interporand((thisVertex.where.xy)/ uni.iResolution ).xzy;
  
  
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
      occ = triOcclusion( pos, nor, v1, v2, v3 );
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
        float rx = ra*cos(tau*aa.x);
        float ry = ra*sin(tau*aa.x);
        float rz = sqrt( 1.0-aa.y );
        float3  dir = float3( rx*ru + ry*rv + rz*nor );
        float3 res = triIntersect( pos+nor*0.001, dir, v1, v2, v3 );
        occ += step(0.0,res.x);
      }
      occ /= 256.0;
    }
    
    col = float3(1.0);
    col *= 1.0 - occ;
  }
  
  float3 res = triIntersect( ro, rd, v1, v2, v3 );
  float t2 = res.x;
  if( t2>0.0 && t2<tmin )
  {
    tmin = t2;
    // float t = t2;
    // float3 pos = ro + t*rd;
    float3 nor = normalize( cross( v2-v1, v3-v1 ) );
    col = float3(1.0,0.8,0.5);
    col *= 1.5*tex.sample( iChannel0, res.yz ).xyz;
    col *= 0.6 + 0.4*nor.y;
  }
  
  col *= exp( -0.05*tmin );
  
  float e = 2.0/uni.iResolution.y;
  col *= smoothstep( 0.0, 2.0*e, abs(p.x-s) );
  
  return float4( col, 1.0 );
}

