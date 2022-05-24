/** 
 Author: iq
 Intersection of an arbitrary parallelogram and a ray (a parallelogram is a quad with two pairs of parallel lines)
 */

#define shaderName parallelogram_intersection

#include "Common.h" 

struct InputBuffer {
};

initialize() {
  // setTex(0, asset::wood);
}




static float3 parallelogramIntersect( float3 ro, float3 rd, float3 v0, float3 v1, float3 v2 )
{
  float3 a = v0 - v1;
  float3 b = v2 - v0;
  float3 p = v0 - ro;

  float3 n = cross( a, b );
  float3 q = cross( rd, p );

  float i = 1.0/dot( rd, n );

  float u = dot( q, a )*i;
  float v = dot( q, b )*i;
  float t = dot( n, p )*i;

  if( u<0.0 || u>1.0 || v<0.0 || v>1.0 ) return float3(-1.0);

  return float3( t, u, v );
}

//=====================================================

static float sphIntersect( float3 ro, float3 rd, float4 sph )
{
  float3 oc = ro - sph.xyz;
  float b = dot( oc, rd );
  float c = dot( oc, oc ) - sph.w*sph.w;
  float h = b*b - c;
  if( h<0.0 ) return -1.0;
  return -b - sqrt( h );
}


static float4 intersect( float3 ro, float3 rd, float3 v0, float3 v1, float3 v2, float3 v3 )
{
  float tmin = 100000.0;
  float obj = -1.0;
  float2  uv = float2(-1.0);

  float t = (-1.0-ro.y)/rd.y;
  if( t>0.0 && t<tmin )
  {
    tmin = t;
    obj = 1.0;
  }
  float3 tuv = parallelogramIntersect( ro, rd, v0, v1, v2 );
  if( tuv.x>0.0 && tuv.x<tmin )
  {
    tmin = tuv.x;
    obj = 2.0;
    uv = tuv.yz;
  }
  t = sphIntersect( ro, rd, float4(v0,0.1) );
  if( t>0.0 && t<tmin )
  {
    tmin = t;
    obj = 3.0;
  }
  t = sphIntersect( ro, rd, float4(v1,0.1) );
  if( t>0.0 && t<tmin )
  {
    tmin = t;
    obj = 4.0;
  }
  t = sphIntersect( ro, rd, float4(v2,0.1) );
  if( t>0.0 && t<tmin )
  {
    tmin = t;
    obj = 5.0;
  }
  t = sphIntersect( ro, rd, float4(v3,0.1) );
  if( t>0.0 && t<tmin )
  {
    tmin = t;
    obj = 6.0;
  }

  return float4(tmin,obj,uv);
}

static float3 calcNormal( float3 pos, float obj, float3 v0, float3 v1, float3 v2, float3 v3 )
{
  if( obj<1.5 )
    return float3(0.0,1.0,0.0);
  else if( obj<2.5 )
    return normalize( cross(v2-v1,v1-v3) );
  else if( obj<3.5 )
    return normalize( pos-v0 );
  else if( obj<4.5 )
    return normalize( pos-v1 );
  else if( obj<5.5 )
    return normalize( pos-v2 );
  else// if( obj<6.5 )
    return normalize( pos-v3 );
}

static float calcShadow( float3 ro, float3 rd, float k, float3 v0, float3 v1, float3 v2, float3 v3 )
{
  return step(intersect(ro,rd, v0, v1, v2, v3).y,0.0);
}


fragmentFn(texture2d<float> tex) {
  float3 lig = normalize(float3(1.0,0.9,0.7));
  float3 v0, v1, v2, v3;

  v0 = 1.5*cos( uni.iTime*1.1 + float3(0.0,1.0,1.0) + 0.0 );
  v1 = 1.0*cos( uni.iTime*1.2 + float3(0.0,2.0,3.0) + 2.0 );
  v2 = 1.0*cos( uni.iTime*1.3 + float3(0.0,3.0,5.0) + 4.0 );
  v3 = v1 + v2 - v0;

  float2 p = worldCoordAspectAdjusted;

  float3 ro = float3(0.0, 0.25, 2.0 );
  float3 rd = normalize( float3(p,-1.0) );

  float3 col = float3(0.0);

  float4 res = intersect(ro,rd, v0, v1, v2, v3);
  float t = res.x;
  float o = res.y;
  float2  uv = res.zw;
  if( o>0.0 )
  {
    float3 pos = ro + t*rd;
    float3 nor = calcNormal(pos, o, v0, v1, v2, v3);
    nor = faceforward( nor, rd, nor );
    float sha = calcShadow( pos + nor*0.01, lig, 32.0, v0, v1, v2, v3 );

    col = (abs(o-2.0)<0.1) ? pow(tex.sample(iChannel0,uv).xyz,float3(1.5)) :
    float3(1.0);

    float3 lin = float3(0.0);
    lin =  float3(0.9,0.6,0.3)*saturate( dot( nor, lig ) ) * sha;
    lin += float3(0.5,0.6,0.7)*saturate( nor.y);
    lin += 0.03;

    col = col*lin;

    col *= exp( -0.2*t );
    col *= 1.0 - smoothstep( 5.0, 10.0, t );
  }

  col = pow( saturate(col), float3(0.45) );

  return float4( col, 1.0 );
}

