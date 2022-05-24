/** 
 Author: iq
 Intersection of a ray and a generic (oriented in any direction) capsule. This computes the intersection with a truncated cylinder and a ONE sphere (as opposed to two).
 */

#define shaderName capsule_intersection

#include "Common.h" 

struct InputBuffer {
};
initialize() {}





// Intersection of a ray and a capped cylinder oriented in an arbitrary direction. There's
// only one sphere involved, not two.


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



// intersect capsule
static float capIntersect( const float3 ro, const float3 rd, const float3 pa, const float3 pb, const float r )
{
  float3  ba = pb - pa;
  float3  oa = ro - pa;

  float baba = dot(ba,ba);
  float bard = dot(ba,rd);
  float baoa = dot(ba,oa);
  float rdoa = dot(rd,oa);
  float oaoa = dot(oa,oa);

  float a = baba      - bard*bard;
  float b = baba*rdoa - baoa*bard;
  float c = baba*oaoa - baoa*baoa - r*r*baba;
  float h = b*b - a*c;
  if( h>=0.0 )
  {
    float t = (-b-sqrt(h))/a;

    float y = baoa + t*bard;

    // body
    if( y>0.0 && y<baba ) return t;

    // caps
    float3 oc = (y<=0.0) ? oa : ro - pb;
    b = dot(rd,oc);
    c = dot(oc,oc) - r*r;
    h = b*b - c;
    if( h>0.0 )
    {
      return -b - sqrt(h);
    }
  }
  return -1.0;
}

// compute normal
static float3 capNormal( const float3 pos, const float3 a, const float3 b, const float r )
{
  float3  ba = b - a;
  float3  pa = pos - a;
  float h = saturate(dot(pa,ba)/dot(ba,ba));
  return (pa - h*ba)/r;
}


// fake occlusion
static float capOcclusion( const float3 p, const float3 n, const float3 a, const float3 b, const float r )
{
  float3  ba = b - a, pa = p - a;
  float h = saturate(dot(pa,ba)/dot(ba,ba));
  float3  d = pa - h*ba;
  float l = length(d);
  float o = 1.0 - max(0.0,dot(-d,n))*r*r/(l*l*l);
  return sqrt(o*o*o);
}

fragmentFn() {
  float2 p = worldCoordAspectAdjusted;

  // camera movement
  float an = 0.5*uni.iTime;
  float3 ro = float3( 1.0*cos(an), 0.4, 1.0*sin(an) );
  float3 ta = float3( 0.0, 0.0, 0.0 );
  // camera matrix
  float3 ww = normalize( ta - ro );
  float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
  float3 vv = normalize( cross(uu,ww));
  // create view ray
  float3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

  const float3  capA = float3(-0.3,-0.1,-0.1);
  const float3  capB = float3(0.3,0.1,0.4);
  const float capR = 0.2;

  float3 col = float3(0.0);

  const float3 lig = normalize(float3(-0.8,0.8,0.2));

  float tmin = 1e20;
  float sha = 1.0;
  float occ = 1.0;
  float3 nor;

  // plane (floor)
  {
    float t = (-0.3-ro.y)/rd.y;
    if( t>0.0 && t<tmin )
    {
      tmin = t;
      float3 pos = ro + t*rd;
      nor = float3(0.0,1.0,0.0);
      // fake soft shadow!
      sha = step( capIntersect( pos+0.001*nor, lig, capA, capB, capR ), 0.0 );
      // fake occlusion
      occ = capOcclusion( pos, nor, capA, capB, capR );
    }
  }

  // capsule
  {
    float t = capIntersect( ro, rd, capA, capB, capR );
    if( t>0.0 && t<tmin )
    {
      tmin = t;
      float3 pos = ro + t*rd;
      nor = capNormal(pos, capA, capB, capR );
      occ = 0.5 + 0.5*nor.y;
      sha = 1.0;
    }
  }

  // lighting
  if( tmin<1e19 )
  {
    float dif = saturate( dot(nor,lig))*sha;
    float amb = 1.0*occ;
    col =  float3(0.2,0.3,0.4)*amb;
    col += float3(0.7,0.6,0.5)*dif*0.8;
  }

  col = sqrt( col );

  return float4( col, 1.0 );
}

