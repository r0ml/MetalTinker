/** 
 Author: iq
 Intersection of a ray and a box. The ray is transformed to box space, and the returned normal is converted back to ray space upon intersection. If there were many boxes to be intersected oriented the same way, the transformations should be done only once.
 */
#define shaderName a_Cube_12

#include "Common.h"

struct InputBuffer {
  };

initialize() {
// setTex(0, asset::rust);
}



// Ray-Box intersection, by convertig the ray to the local space of the box.
//
// Form http://iquilezles.org/www/articles/intersectors/intersectors.htm
//
// If this was used to raytace many equally oriented boxes (say you are traversing
// a BVH), then the transformations in line 34 and 35 could be skipped, as well as
// the normal computation in line 50. One over the ray direction is usually accessible
// as well in raytracers, so the division would go away in real world applications.

// Other intersectors:
//
// Box:       https://www.shadertoy.com/view/ld23DV
// Triangle:  https://www.shadertoy.com/view/MlGcDz
// Capsule:   https://www.shadertoy.com/view/Xt3SzX
// Ellipsoid: https://www.shadertoy.com/view/MlsSzn
// Sphere:    https://www.shadertoy.com/view/4d2XWV
// Cylinder:  https://www.shadertoy.com/view/4lcSRn
// Disk:      https://www.shadertoy.com/view/lsfGDB
// Torus:     https://www.shadertoy.com/view/4sBGDy

// returns t and normal
static float4 iBox( const float3 ro, const float3 rd, const float4x4 txx, const float4x4 txi, const float3 rad ) 
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

float sBox( const float3 ro, const float3 rd, const float4x4 txx, const float3 rad ) 
{
  float3 rdd = (txx*float4(rd,0.0)).xyz;
  float3 roo = (txx*float4(ro,1.0)).xyz;
  
  float3 m = 1.0/rdd;
  float3 n = m*roo;
  float3 k = abs(m)*rad;
  
  float3 t1 = -n - k;
  float3 t2 = -n + k;
  
  float tN = max( max( t1.x, t1.y ), t1.z );
  float tF = min( min( t2.x, t2.y ), t2.z );
  if( tN > tF || tF < 0.0) return -1.0;
  
  return tN;
}

//-----------------------------------------------------------------------------------------

float4x4 rotationAxisAngle( float3 v, float angle )
{
  float s = sin( angle );
  float c = cos( angle );
  float ic = 1.0 - c;
  
  return float4x4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                  v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                  v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
                  0.0,                0.0,                0.0,                1.0 );
}

float4x4 translate( float x, float y, float z )
{
  return float4x4( 1.0, 0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0,
                  x,   y,   z,   1.0 );
}
/*
 float4x4 inverse( const float4x4 m )
 {
 return float4x4(
 m[0][0], m[1][0], m[2][0], 0.0,
 m[0][1], m[1][1], m[2][1], 0.0,
 m[0][2], m[1][2], m[2][2], 0.0,
 -dot(m[0].xyz,m[3].xyz),
 -dot(m[1].xyz,m[3].xyz),
 -dot(m[2].xyz,m[3].xyz),
 1.0 );
 }*/

fragmentFn(texture2d<float> tex) {
  float2 p = worldCoordAspectAdjusted;
  
  // camera movement
  float an = 0.4*uni.iTime;
  float3 ro = float3( 2.5*cos(an), 1.0, 2.5*sin(an) );
  float3 ta = float3( 0.0, 0.8, 0.0 );
  // camera matrix
  float3 ww = normalize( ta - ro );
  float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
  float3 vv = normalize( cross(uu,ww));
  // create view ray
  float3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );
  
  // rotate and translate box
  float4x4 rot = rotationAxisAngle( normalize(float3(1.0,1.0,0.0)), uni.iTime );
  float4x4 tra = translate( 0.0, 1.0, 0.0 );
  float4x4 txi = tra * rot;
  float4x4 txx = inverse( txi );
  
  // raytrace
  float tmin = 10000.0;
  float3  nor = float3(0.0);
  float3  pos = float3(0.0);
  
  // raytrace-plane
  float oid = 0.0;
  float h = (0.0-ro.y)/rd.y;
  if( h>0.0 )
  {
    tmin = h;
    nor = float3(0.0,1.0,0.0);
    oid = 1.0;
  }
  
  // raytrace box
  float3 box = float3(0.4,0.6,0.8) ;
  float4 res = iBox( ro, rd, txx, txi, box);
  if( res.x>0.0 && res.x<tmin )
  {
    tmin = res.x;
    nor = res.yzw;
    oid = 2.0;
  }
  
  // shading/lighting
  float3 col = float3(0.9);
  if( tmin<100.0 )
  {
    float3 lig = normalize(float3(-0.8,0.4,0.1));
    pos = ro + tmin*rd;
    
    // material
    float occ = 1.0;
    float3  mate = float3(1.0);
    if( oid<1.5 ) // plane
    {
      mate = tex.sample( iChannel0, 0.25*pos.xz ).xyz;
      occ = 0.2 + 0.8*smoothstep( 0.0, 1.5, length(pos.xz) );
    }
    else // box
    {
      // recover box space data (we want to do shading const object space)
      float3 opos = (txx*float4(pos,1.0)).xyz;
      float3 onor = (txx*float4(nor,0.0)).xyz;
      mate = abs(onor.x)*tex.sample( iChannel0, 0.5*opos.yz ).xyz +
      abs(onor.y)*tex.sample( iChannel0, 0.5*opos.zx ).xyz +
      abs(onor.z)*tex.sample( iChannel0, 0.5*opos.xy ).xyz;
      
      // wireframe
      mate *= 1.0 - (1.0-abs(onor.x))*smoothstep( box.x-0.04, box.x-0.02, abs(opos.x) );
      mate *= 1.0 - (1.0-abs(onor.y))*smoothstep( box.y-0.04, box.y-0.02, abs(opos.y) );
      mate *= 1.0 - (1.0-abs(onor.z))*smoothstep( box.z-0.04, box.z-0.02, abs(opos.z) );
      
      occ = 0.6 + 0.4*nor.y;
    }
    mate = mate*mate*1.5;
    
    // lighting
    float dif = saturate( dot(nor,lig));
    dif *= step( sBox( pos+0.01*nor, lig, txx, box ), 0.0 );
    col = float3(0.13,0.17,0.2)*occ*3.0 + 1.5*dif*float3(1.0,0.9,0.8);
    
    // material * lighting
    col *= mate;
    
    // fog
    col = mix( col, float3(0.9), 1.0-exp( -0.003*tmin*tmin ) );
  }
  
  col = sqrt( col );
  
  return float4( col, 1.0 );
}
