

#define shaderName a_Triangle

#include "Common.h" 

struct InputBuffer {};
initialize() {}


static float dot2( float3 v ) { return dot(v,v); }

static float udTriangle( float3 v1, float3 v2, float3 v3, float3 p )
{
  float3 v21 = v2 - v1; float3 p1 = p - v1;
  float3 v32 = v3 - v2; float3 p2 = p - v2;
  float3 v13 = v1 - v3; float3 p3 = p - v3;
  float3 nor = cross( v21, v13 );
  
  return sqrt( (sign(dot(cross(v21,nor),p1)) +
                sign(dot(cross(v32,nor),p2)) +
                sign(dot(cross(v13,nor),p3))<2.0)
              ?
              min( min(
                       dot2(v21*saturate(dot(v21,p1)/dot2(v21))-p1),
                       dot2(v32*saturate(dot(v32,p2)/dot2(v32))-p2) ),
                  dot2(v13*saturate(dot(v13,p3)/dot2(v13))-p3) )
              :
              dot(nor,p1)*dot(nor,p1)/dot2(nor) );
}

//=====================================================

static float map( float3 p, float time )
{
  // triangle
  float3 v1 = 1.5*cos( time + float3(0.0,1.0,1.0) + 0.0 );
  float3 v2 = 1.0*cos( time + float3(0.0,2.0,3.0) + 2.0 );
  float3 v3 = 1.0*cos( time + float3(0.0,3.0,5.0) + 4.0 );
  float d1 = udTriangle( v1, v2, v3, p ) - 0.01;
  
  // ground plane
  float d2 = p.y + 1.0;
  
  return min( d1, d2 );
}

static float intersect( float3 ro, float3 rd, float time )
{
  const float maxd = 10.0;
  float h = 1.0;
  float t = 0.0;
  for( int i=0; i<50; i++ )
  {
    if( h<0.001 || t>maxd ) break;
    h = map( ro+rd*t, time );
    t += h;
  }
  
  if( t>maxd ) t=-1.0;
  
  return t;
}

static float3 calcNormal( float3 pos, float time )
{
  float3 eps = float3(0.002,0.0,0.0);
  
  return normalize( float3(
                           map(pos+eps.xyy, time) - map(pos-eps.xyy, time),
                           map(pos+eps.yxy, time) - map(pos-eps.yxy, time),
                           map(pos+eps.yyx, time) - map(pos-eps.yyx, time) ) );
}

static float calcSoftshadow( float3 ro, float3 rd, float k, float time )
{
  float res = 1.0;
  float t = 0.0;
  float h = 1.0;
  for( int i=0; i<20; i++ )
  {
    h = map(ro + rd*t, time);
    res = min( res, k*h/t );
    t += clamp( h, 0.01, 1.0 );
    if( h<0.0001 ) break;
  }
  return saturate(res);
}

static float calcOcclusion( float3 pos, float3 nor , float time)
{
  float occ = 0.0;
  float sca = 1.0;
  for( int i=0; i<5; i++ )
  {
    float hr = 0.02 + 0.025*float(i*i);
    float3 aopos =  nor * hr + pos;
    float dd = map( aopos, time );
    occ += -(dd-hr)*sca;
    sca *= 0.95;
  }
  return 1.0 - saturate( occ);
}

fragmentFn() {
  const float3 lig = normalize(float3(1.0,0.9,0.7));
  
  float2 p = worldCoordAspectAdjusted;

  float3 ro = float3(0.0, 0.25, 2.0 );
  float3 rd = normalize( float3(p,-1.0) );
  
  float3 col = float3(0.0);
  
  float t = intersect(ro,rd, uni.iTime);
  if( t>0.0 )
  {
    float3 pos = ro + t*rd;
    float3 nor = calcNormal(pos, uni.iTime);
    float sha = calcSoftshadow( pos + nor*0.01, lig, 32.0, uni.iTime );
    float occ = calcOcclusion( pos, nor, uni.iTime );
    col =  float3(0.9,0.6,0.3)*saturate( dot( nor, lig )) * sha;
    col += float3(0.5,0.6,0.7)*saturate( nor.y)*occ;
    col += 0.03;
    col *= exp( -0.2*t );
    col *= 1.0 - smoothstep( 5.0, 10.0, t );
  }
  
  col = pow( saturate(col), float3(0.45) );
  
  return float4( col, 1.0 );
}

