/** 
 Author: iq
 Analytical computation of the exact bounding box for an arbitrarily oriented disk. See [url]http://iquilezles.org/www/articles/diskbbox/diskbbox.htm[/url] for the derivation.
 */
#define shaderName a_Cylinder_5

#include "Common.h"

struct InputBuffer {};

initialize() { }



// See http://iquilezles.org/www/articles/diskbbox/diskbbox.htm
//
//
// Analytical computation of the exact bounding box for an arbitrarily oriented disk. 
// It took me a good two hours to find the symmetries and term cancellations that 
// simplified the original monster equation into something pretty compact in its final form.
//
// For a disk of raius r centerd in the origin oriented in the direction n, has extent e:
//
// e = r·sqrt(1-n²)
//
// Derivation and more info in the link above

// Disk bounding box:      https://www.shadertoy.com/view/ll3Xzf
// Cylinder bounding box:  https://www.shadertoy.com/view/MtcXRf
// Ellipse bounding box:   https://www.shadertoy.com/view/Xtjczw

struct bound3
{
  float3 mMin;
  float3 mMax;
};

//---------------------------------------------------------------------------------------
// bounding box for a cylinder (http://iquilezles.org/www/articles/diskbbox/diskbbox.htm)
//---------------------------------------------------------------------------------------
bound3 CylinderAABB( const float3 pa, const float3 pb, const float ra )
{
  float3 a = pb - pa;
  float3 e = ra*sqrt( 1.0 - a*a/dot(a,a) );
  
  return bound3 {  min( pa - e, pb - e ), max( pa + e, pb + e )  } ;
}

// ray-cylinder intersetion (returns t and normal)
float4 iCylinder( const float3 ro, const float3 rd, 
                 const float3 pa, const float3 pb, const float ra ) // point a, point b, radius
{
  // center the cylinder, normalize axis
  float3 cc = 0.5*(pa+pb);
  float ch = length(pb-pa);
  float3 ca = (pb-pa)/ch;
  ch *= 0.5;
  
  float3  oc = ro - cc;
  
  float card = dot(ca,rd);
  float caoc = dot(ca,oc);
  
  float a = 1.0 - card*card;
  float b = dot( oc, rd) - caoc*card;
  float c = dot( oc, oc) - caoc*caoc - ra*ra;
  float h = b*b - a*c;
  if( h<0.0 ) return float4(-1.0);
  h = sqrt(h);
  float t1 = (-b-h)/a;
  //float t2 = (-b+h)/a; // exit point
  
  float y = caoc + t1*card;
  
  // body
  if( abs(y)<ch ) return float4( t1, normalize( oc+t1*rd - ca*y ) );
  
  // caps
  float sy = sign(y);
  float tp = (sy*ch - caoc)/card;
  if( abs(b+a*tp)<h )
  {
    return float4( tp, ca*sy );
  }
  
  return float4(-1.0);
}

// ray-box intersection
static float2 iBox( const float3 ro, const float3 rd, const float3 cen, const float3 rad ) 
{
  float3 m = 1.0/rd;
  float3 n = m*(ro-cen);
  float3 k = abs(m)*rad;
  
  float3 t1 = -n - k;
  float3 t2 = -n + k;
  
  float tN = max( max( t1.x, t1.y ), t1.z );
  float tF = min( min( t2.x, t2.y ), t2.z );
  
  if( tN > tF || tF < 0.0) return float2(-1.0);
  
  return float2( tN, tF );
}

float hash1( const float2 p )
{
  return fract(sin(dot(p, float2(12.9898, 78.233)))*43758.5453);
}

fragmentFn() {
  float3 tot = float3(0.0);
  
  float2 p = worldCoordAspectAdjusted;

  // camera position
  float3 ro = float3( -0.5, 0.4, 1.5 );
  float3 ta = float3( 0.0, 0.0, 0.0 );
  // camera matrix
  float3 ww = normalize( ta - ro );
  float3 uu = normalize( cross(ww,float3(0.0,1.0,0.0) ) );
  float3 vv = normalize( cross(uu,ww));
  // create view ray
  float3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

  // cylidner animation
  float3  c_a =  0.2 + 0.3*sin(uni.iTime*float3(1.11,1.27,1.47)+float3(2.0,5.0,6.0));
  float3  c_b = -0.2 + 0.3*sin(uni.iTime*float3(1.23,1.41,1.07)+float3(0.0,1.0,3.0));
  float c_r =  0.3 + 0.2*sin(uni.iTime*1.3+0.5);

  // render
  float3 col = float3(0.4)*(1.0-0.3*length(p));

  // raytrace
  float4 tnor = iCylinder( ro, rd, c_a, c_b, c_r );
  float t = tnor.x;
  float tmin = 1e10;
  if( t>0.0 )
  {
    tmin = t;
    // shading/lighting
    //            float3 pos = ro + t*rd;
    float3 nor = tnor.yzw;
    float dif = clamp( dot(nor,float3(0.5,0.7,0.2)), 0.0, 1.0 );
    float amb = 0.5 + 0.5*dot(nor,float3(0.0,1.0,0.0));
    col = sqrt( float3(0.2,0.3,0.4)*amb + float3(0.8,0.7,0.5)*dif );
    col *= float3(1.0,0.75,0.3);
  }

  // compute bounding box of cylinder
  bound3 bbox = CylinderAABB( c_a, c_b, c_r );

  // raytrace bounding box
  float3 bcen = 0.5*(bbox.mMin+bbox.mMax);
  float3 brad = 0.5*(bbox.mMax-bbox.mMin);
  float2 tbox = iBox( ro, rd, bcen, brad );
  if( tbox.x>0.0 )
  {
    // back face
    if( tbox.y < tmin )
    {
      float3 pos = ro + rd*tbox.y;
      float3 e = smoothstep( brad-0.03, brad-0.02, abs(pos-bcen) );
      float al = 1.0 - (1.0-e.x*e.y)*(1.0-e.y*e.z)*(1.0-e.z*e.x);
      col = mix( col, float3(0.0), 0.25 + 0.75*al );
    }
    // front face
    if( tbox.x < tmin )
    {
      float3 pos = ro + rd*tbox.x;
      float3 e = smoothstep( brad-0.03, brad-0.02, abs(pos-bcen) );
      float al = 1.0 - (1.0-e.x*e.y)*(1.0-e.y*e.z)*(1.0-e.z*e.x);
      col = mix( col, float3(0.0), 0.15 + 0.85*al );
    }
  }

  tot += col;

  // dithering
  tot += ((hash1(thisVertex.where.xy)+hash1(thisVertex.where.xy.yx+13.1))/2.0 - 0.5)/256.0;
  
  return float4( tot, 1.0 );
}
