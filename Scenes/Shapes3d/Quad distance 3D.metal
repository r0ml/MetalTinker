/** 
 Author: iq
 Distance field to a quad, petty much an extension to [url]https://www.shadertoy.com/view/4sXXRN[/url]
 */

// It computes the distance to a quad.
//
// In case a whole mesh was rendered, only one square root would be needed for the
// whole mesh.
//
// In this example the quad is given a thickness of 0.01 units (line 47). Like the
// square root, this thickness should be added only once for the whole mesh too.

#define shaderName quad_distance_3d

#include "Common.h" 

struct InputBuffer {
};
initialize() {}




static float dot2( float3 v ) { return dot(v,v); }

static float udQuad( float3 v1, float3 v2, float3 v3, float3 v4, float3 p )
{
  // handle ill formed quads
  if( dot( cross( v2-v1, v4-v1 ), cross( v4-v3, v2-v3 )) < 0.0 )
  {
    float3 tmp = v3;
    v3 = v4;
    v4 = tmp;
  }


  float3 v21 = v2 - v1; float3 p1 = p - v1;
  float3 v32 = v3 - v2; float3 p2 = p - v2;
  float3 v43 = v4 - v3; float3 p3 = p - v3;
  float3 v14 = v1 - v4; float3 p4 = p - v4;
  float3 nor = cross( v21, v14 );

  return sqrt( (sign(dot(cross(v21,nor),p1)) +
                sign(dot(cross(v32,nor),p2)) +
                sign(dot(cross(v43,nor),p3)) +
                sign(dot(cross(v14,nor),p4))<3.0)
              ?
              min( min( dot2(v21*saturate(dot(v21,p1)/dot2(v21))-p1),
                       dot2(v32*saturate(dot(v32,p2)/dot2(v32))-p2) ),
                  min( dot2(v43*saturate(dot(v43,p3)/dot2(v43))-p3),
                      dot2(v14*saturate(dot(v14,p4)/dot2(v14))-p4) ))
              :
              dot(nor,p1)*dot(nor,p1)/dot2(nor) );
}

//=====================================================

static float map( float3 p , const float time)
{
  // triangle
  float3 v1 = 1.5*cos( time*1.1 + float3(0.0,1.0,1.0) + 0.0 );
  float3 v2 = 1.0*cos( time*1.2 + float3(0.0,2.0,3.0) + 2.0 );
  float3 v3 = 1.0*cos( time*1.3 + float3(0.0,3.0,5.0) + 4.0 );
  float3 v4 = v1 + ( v3 - v2);
  float d1 = udQuad( v1, v2, v3, v4, p ) - 0.01;

  // ground plane
  float d2 = p.y + 1.0;

  return min( d1, d2 );
}

static float intersect( float3 ro, float3 rd , const float time)
{
  const float maxd = 10.0;
  float h = 1.0;
  float t = 0.0;
  for( int i=0; i<50; i++ )
  {
    if( h<0.001 || t>maxd ) break;
    h = map( ro+rd*t , time);
    t += h;
  }

  if( t>maxd ) t=-1.0;

  return t;
}

static float3 calcNormal( float3 pos , const float time)
{
  float3 eps = float3(0.002,0.0,0.0);

  return normalize( float3(
                           map(pos+eps.xyy, time) - map(pos-eps.xyy, time),
                           map(pos+eps.yxy, time) - map(pos-eps.yxy, time),
                           map(pos+eps.yyx, time) - map(pos-eps.yyx, time) ) );
}

static float calcSoftshadow( float3 ro, float3 rd, float k , const float time)
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

static float calcOcclusion( float3 pos, float3 nor, const float time )
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
  float3 lig = normalize(float3(1.0,0.9,0.7));

  float2 p = worldCoordAspectAdjusted;

  float3 ro = float3(0.0, 0.25, 2.0 );
  float3 rd = normalize( float3(p,-1.0) );

  float3 col = float3(0.0);

  float t = intersect(ro,rd, uni.iTime);
  if( t>0.0 )
  {
    float3 pos = ro + t*rd;
    float3 nor = calcNormal(pos, uni.iTime);
    float sha = calcSoftshadow( pos + nor*0.01, lig, 32.0 , uni.iTime);
    float occ = calcOcclusion( pos, nor, uni.iTime);
    col =  float3(0.9,0.6,0.3)*saturate( dot( nor, lig )) * sha;
    col += float3(0.5,0.6,0.7)*saturate( nor.y)*occ;
    col += 0.03;
    col *= exp( -0.2*t );
    col *= 1.0 - smoothstep( 5.0, 10.0, t );
  }

  col = pow( saturate(col), float3(0.45) );

  return float4( col, 1.0 );
}

