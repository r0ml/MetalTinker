
#define shaderName a_Triangle_2

#include "Common.h" 

struct InputBuffer {};
initialize() {}


// Triangle intersection. Returns { t, u, v }
static float3 triIntersect( float3 ro, float3 rd, float3 v0, float3 v1, float3 v2 )
{
  float3 v1v0 = v1 - v0;
  float3 v2v0 = v2 - v0;
  float3 rov0 = ro - v0;
  
  // Cramer's rule for solcing p(t) = ro+t·rd = p(u,v) = vo + u·(v1-v0) + v·(v2-v1)
  float d = 1.0/determinant(float3x3(v1v0, v2v0, -rd ));
  float u =   d*determinant(float3x3(rov0, v2v0, -rd ));
  float v =   d*determinant(float3x3(v1v0, rov0, -rd ));
  float t =   d*determinant(float3x3(v1v0, v2v0, rov0));
  
  if( u<0.0 || u>1.0 || v<0.0 || (u+v)>1.0 ) t = -1.0;
  
  return float3( t, u, v );
}

// Triangle occlusion (if fully visible)
static float triOcclusion( float3 pos, float3 nor, float3 v0, float3 v1, float3 v2 )
{
  float3 a = normalize(v0-pos);
  float3 b = normalize(v1-pos);
  float3 c = normalize(v2-pos);
  
  float s = -sign(dot(v0-pos,cross(v0-v1,v2-v1))); // other side of the triangle
  
  // page 300 in http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.466.963&rep=rep1&type=pdf
  float r = dot(nor,normalize(cross(a,b))) * acos(dot(a,b)) +
  dot(nor,normalize(cross(b,c))) * acos(dot(b,c)) +
  dot(nor,normalize(cross(c,a))) * acos(dot(c,a));
  
  return 1.0-max(0.0,s*r)/tau;
}

//=====================================================

static float iPlane( float3 ro, float3 rd )
{
  return (-1.0 - ro.y)/rd.y;
}

//=====================================================

static float gridTexture( float2 p )
{
  const float N = 20.0; // grid ratio
  
  // filter kernel
  float2 w = max(abs(dfdx(p)), abs(dfdy(p))) + 0.001;
  //float2 w = fwidth(p);
  
  // analytic (box) filtering
  float2 a = p + 0.5*w;
  float2 b = p - 0.5*w;
  float2 i = (floor(a)+min(fract(a)*N,1.0)-
              floor(b)-min(fract(b)*N,1.0))/(N*w);
  //pattern
  return (1.0-i.x)*(1.0-i.y);
}

//=====================================================

fragmentFn() {
  float2 p = worldCoordAspectAdjusted;
  
  float3 ro = float3(0.0, 0.0, 4.0 );
  float3 rd = normalize( float3(p,-2.0) );
  
  // triangle animation
  float3 v1 = cos( uni.iTime*1.0 + float3(2.0,1.0,1.0) + 0.0 )*float3(1.5,1.0,1.0);
  float3 v2 = cos( uni.iTime*1.0 + float3(5.0,2.0,3.0) + 2.0 )*float3(1.5,1.0,1.0);
  float3 v3 = cos( uni.iTime*1.2 + float3(1.0,3.0,5.0) + 4.0 )*float3(1.5,1.0,1.0);
  
  float3 col = float3(1.0);
  
  float tmin = 1e10;
  
  float t1 = iPlane( ro, rd );
//  float t1 = sdPlane( ro );

  if( t1>0.0 )
  {
    tmin = t1;
    float3 pos = ro + tmin*rd;
    float3 nor = float3(0.0,1.0,0.0);
    col = float3(0.9) * gridTexture( 4.0*pos.xz );
    col *= triOcclusion( pos, nor, v1, v2, v3 );
    col = mix( col, float3(1.0), 1.0-exp(-0.002*tmin) );
  }
  
  float3 res = triIntersect( ro, rd, v1, v2, v3 );
  float t2 = res.x;
  if( t2>0.0 && t2<tmin )
  {
    tmin = t2;
    // float t = t2;
    // float3 pos = ro + t*rd;
    float3 nor = normalize( cross( v2-v1, v3-v1 ) );
    col = float3(res.yz,0.0) * gridTexture( 15.0*res.yz );
    col *= 0.55 + 0.45*faceforward(-nor, -rd, nor).y;
  }
  
  
  col = pow( col, float3(0.4545) );
  
  return float4( col, 1.0 );
}
