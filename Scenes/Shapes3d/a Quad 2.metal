/** 
 Author: iq
 Inverse bilinear interpolation: given a point p and a quad compute the bilinear coordinates of p in the quad. More info [url=http://www.iquilezles.org/www/articles/ibilinear/ibilinear.htm]in this article[/url].
 */

// Inverse bilinear interpolation: given four points defining a quadrilateral, compute the uv
// coordinates of any point in the plane that would give result to that point as a bilinear 
// interpolation of the four points.
//
// The problem can be solved through a quadratic equation. More information in this article:
//
// http://www.iquilezles.org/www/articles/ibilinear/ibilinear.htm

#define shaderName a_Quad_2

#include "Common.h" 

struct InputBuffer {
  };

initialize() {
// setTex(0, asset::lichen);
}



// given a point p and a quad defined by four points {a,b,c,d}, return the bilinear
// coordinates of p in the quad. Returns (-1,-1) if the point is outside of the quad.
static float2 invBilinear( float2 p, float2 a, float2 b, float2 c, float2 d )
{
  float2 res = float2(-1.0);
  
  float2 e = b-a;
  float2 f = d-a;
  float2 g = a-b+c-d;
  float2 h = p-a;
  
  float k2 = cross( g, f );
  float k1 = cross( e, f ) + cross( h, g );
  float k0 = cross( h, e );
  
  // if edges are parallel, this is a linear equation. Do not this test here though, do
  // it in the user code
  //if( abs(k2)<0.001 )
  //{
  //	  float v = -k0/k1;
  //    float u  = (h.x*k1+f.x*k0) / (e.x*k1-g.x*k0);
  //
  //    if( v>0.0 && v<1.0 && u>0.0 && u<1.0 )  res = float2( u, v );
  //}
  //else
  {
    // otherwise, it's a quadratic
    float w = k1*k1 - 4.0*k0*k2;
    if( w<0.0 ) return float2(-1.0);
    w = sqrt( w );
    
    float ik2 = 0.5/k2;
    float v = (-k1 - w)*ik2; if( v<0.0 || v>1.0 ) v = (-k1 + w)*ik2;
    float u = (h.x - f.x*v)/(e.x + g.x*v);
    if( u<0.0 || u>1.0 || v<0.0 || v>1.0 ) return float2(-1.0);
    res = float2( u, v );
  }
  
  return res;
}

static float3  hash3( float n ) { return fract(sin(float3(n,n+1.0,n+2.0))*43758.5453123); }

fragmentFn(texture2d<float> tex) {
  float2 p = worldCoordAspectAdjusted;
  
  // background
  float3 col = float3( 0.35 + 0.1*p.y );
  
  // move points
  float2 a = cos( 1.11*uni.iTime + float2(0.1,4.0) );
  float2 b = cos( 1.13*uni.iTime + float2(1.0,3.0) );
  float2 c = cos( 1.17*uni.iTime + float2(2.0,2.0) );
  float2 d = cos( 1.15*uni.iTime + float2(3.0,1.0) );
  
  // area of the quad
  float2 uv = invBilinear( p, a, b, c, d );
  if( uv.x>-0.5 )
  {
    col = tex.sample( iChannel0, uv ).xyz;
  }
  
  // quad borders
  float h = 2.0/uni.iResolution.y;
  col = mix( col, float3(1.0,0.7,0.2), 1.0-smoothstep(h,2.0*h,sdSegment(p,a,b)));
  col = mix( col, float3(1.0,0.7,0.2), 1.0-smoothstep(h,2.0*h,sdSegment(p,b,c)));
  col = mix( col, float3(1.0,0.7,0.2), 1.0-smoothstep(h,2.0*h,sdSegment(p,c,d)));
  col = mix( col, float3(1.0,0.7,0.2), 1.0-smoothstep(h,2.0*h,sdSegment(p,d,a)));
  
  col += (1.0/255.0)*hash3(p.x+13.0*p.y);
  
  return float4( col, 1.0 );
}
