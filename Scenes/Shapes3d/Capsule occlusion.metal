/**
 Author: iq
 Fake occlusion from an ellipsoids (into any surface)
 */

// Fake occlusion from a capsule into arbitrary surfaces.

#define shaderName capsule_occlusion

#include "Common.h" 

struct InputBuffer {
};

initialize() {
}






// Other shaders with analytical occlusion or approximations:
// 
// Box:                        https://www.shadertoy.com/view/4djXDy
// Box with horizon clipping:  https://www.shadertoy.com/view/4sSXDV
// Triangle:                   https://www.shadertoy.com/view/XdjSDy
// Sphere:                     https://www.shadertoy.com/view/4djSDy
// Ellipsoid (approximation):  https://www.shadertoy.com/view/MlsSzn
// Capsule (approximation):    https://www.shadertoy.com/view/llGyzG



// define this to compare to grount truth
//#define SHOW_REAL_OCCLUSION



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
static float capOcclusion( const float3 p, const float3 n, const float3 a, const float3 b, const  float r )
{
  // closest sphere
  float3  ba = b - a, pa = p - a;
  float h = saturate(dot(pa,ba)/dot(ba,ba));
  float3  d = pa - h*ba;
  float l = length(d);
  float o = 1.0 - max(0.0,dot(-d,n))*r*r/(l*l*l);
  // tune
  return sqrt(o*o*o);
}

// static float2 hash2( float n ) { return fract(sin(float2(n,n+1.0))*float2(43758.5453123,22578.1459123)); }

fragmentFn() {
  float2 p = worldCoordAspectAdjusted;

  // camera movement
  float an = 0.5*uni.iTime;
  float3 ro = float3( 1.0*cos(an), 0.5, 1.0*sin(an) );
  float3 ta = float3( 0.0, 0.0, 0.0 );
  // camera matrix
  float3 ww = normalize( ta - ro );
  float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
  float3 vv = normalize( cross(uu,ww));
  // create view ray
  float3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

  // float4 rrr = texture[0].sample( iChannel0, (thisVertex.where.xy)/textureSize(texture[0]), bias(-99.0)  ).xzyw;


  float3  capA = float3(0.0,0.3,0.0) + float3(0.5,0.15,0.5)*cos( uni.iTime*1.1 + float3(0.0,1.0,4.0) );
  float3  capB = float3(0.0,0.3,0.0) + float3(0.5,0.15,0.5)*cos( uni.iTime*1.7 + float3(2.0,5.0,3.0) );
  const float capR = 0.15;

  float3 col = float3(0.0);

  // const float3 lig = normalize(float3(-0.8,0.8,0.2));

  // capsule
  float tmin = 1e20;
  float occ = 1.0;
  float3 nor;

  {
    float t = capIntersect( ro, rd, capA, capB, capR );
    if( t>0.0 )
    {
      tmin = t;
      float3 pos = ro + t*rd;
      nor = capNormal(pos, capA, capB, capR );
      col = float3( 0.5 + 0.5*nor.y );
    }
  }
  // plane (floor)
  {
    float t = (-0.0-ro.y)/rd.y;
    if( t>0.0 && t<tmin )
    {
      tmin = t;
      float3 pos = ro + t*rd;
      nor = float3(0.0,1.0,0.0);

#ifndef SHOW_REAL_OCCLUSION

      occ = capOcclusion( pos, nor, capA, capB, capR );

#else
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
        float res = capIntersect( pos, dir, capA, capB, capR );
        occ += step(0.0,res);
      }
      occ = 1.0 - occ/256.0;
#endif

      col = float3(occ);


      // fake occlusion
    }
  }

  col = sqrt( col );

  return float4( col, 1.0 );
}

