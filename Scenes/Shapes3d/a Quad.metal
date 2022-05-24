/** 
 Author: iq
 Tests whether a point is inside a quad. Note than the quadrilateral can intersect itself. Derived from https://www.shadertoy.com/view/lsBSDm
 */
#define shaderName a_Quad

#include "Common.h"
struct InputBuffer {  };
initialize() {}

// Point in Quad test. Note that it works for selfintersecting quads. No square roots
// required. Derived form this shader: https://www.shadertoy.com/view/lsBSDm

static float pointInQuad( const float2 p, const float2 a, const float2 b, const float2 c, const float2 d )
{
  float2 e = b-a;
  float2 f = a-d;
  float2 g = a-b+c-d;
  float2 h = p-a;
  
  float k0 = cross( f, g );
  float k1 = cross( e, g );
  float k2 = cross( f, e );
  float k3 = cross( g, h );
  float k4 = cross( e, h );
  float k5 = cross( f, h );
  
  float l0 = k2 - k3 + k0;
  float l1 = k2 + k3 + k1;
  float m0 = l0*l0 + k0*(2.0*k4 - l0);
  float m1 = l1*l1 + k1*(2.0*k5 - l1);
  float n0 = m0    + k0*(2.0*k4 + k3 - k2);
  float n1 = m1    + k1*(2.0*k5 - k3 - k2);
  
  float b0 = step( m0*m0, l0*l0*n0 );
  float b1 = step( m1*m1, l1*l1*n1 );
  
  float res = (m0>0.0) ? ((m1>0.0) ? b1*b0 :
                          b0) :
  ((m1>0.0) ? b1 :
   b1 + b0 - b1*b0);
  
  if( l0*l1 < 0.0 )  res -= b1*b0;
  
  return res;
}

fragmentFn() {
  float2 p = worldCoordAspectAdjusted;
  
  float2 a = cos( 1.11*uni.iTime + float2(0.1,4.0) );
  float2 b = cos( 1.13*uni.iTime + float2(1.0,3.0) );
  float2 c = cos( 1.17*uni.iTime + float2(2.0,2.0) );
  float2 d = cos( 1.15*uni.iTime + float2(3.0,1.0) );
  
  float isQuad = pointInQuad( p, a, b, c, d );
  
  float3 col = float3( isQuad*0.5 );
  
  float h = 2.0/uni.iResolution.y;
  col = mix( col, float3(1.0), 1.0-smoothstep(h,2.0*h,sdSegment(p,a,b)));
  col = mix( col, float3(1.0), 1.0-smoothstep(h,2.0*h,sdSegment(p,b,c)));
  col = mix( col, float3(1.0), 1.0-smoothstep(h,2.0*h,sdSegment(p,c,d)));
  col = mix( col, float3(1.0), 1.0-smoothstep(h,2.0*h,sdSegment(p,d,a)));
  
  return float4( col,1.0);
}
