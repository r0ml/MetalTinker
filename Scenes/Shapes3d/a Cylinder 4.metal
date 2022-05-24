
#define shaderName a_Cylinder_4

#include "Common.h"

struct InputBuffer { };
initialize() {}


static float4 iCylinder( const float3 ro, const float3 rd,
                 const float3 pa, const float3 pb, float ra ) // extreme a, extreme b, radius
{
  float3 ca = pb-pa;
  
  float3  oc = ro - pa;
  
  float caca = dot(ca,ca);
  float card = dot(ca,rd);
  float caoc = dot(ca,oc);
  
  float a = caca - card*card;
  float b = caca*dot( oc, rd) - caoc*card;
  float c = caca*dot( oc, oc) - caoc*caoc - ra*ra*caca;
  float h = b*b - a*c;
  if( h<0.0 ) return float4(-1.0);
  h = sqrt(h);
  float t = (-b-h)/a;
  
  // body
  float y = caoc + t*card;
  if( y>0.0 && y<caca ) return float4( t, (oc+t*rd - ca*y/caca)/ra );
  
  // caps
  t = ( ((y<0.0) ? 0.0 : caca) - caoc)/card;
  if( abs(b+a*t)<h )
  {
    return float4( t, ca*sign(y)/caca );
  }
  
  return float4(-1.0);
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
  
  
  // raytrace
  float4 tnor = iCylinder( ro, rd, float3(-0.2,-0.3,-0.1), float3(0.3,0.3,0.4), 0.2 );
  float t = tnor.x;
  
  // shading/lighting
  float3 col = float3(0.0);
  if( t>0.0 )
  {
    //    float3 pos = ro + t*rd;
    float3 nor = tnor.yzw;
    float dif = clamp( dot(nor,float3(0.57703)), 0.0, 1.0 );
    float amb = 0.5 + 0.5*dot(nor,float3(0.0,1.0,0.0));
    col = float3(0.2,0.3,0.4)*amb + float3(0.8,0.7,0.5)*dif;
  }
  
  col = sqrt( col );
  
  return float4( col, 1.0 );
}
