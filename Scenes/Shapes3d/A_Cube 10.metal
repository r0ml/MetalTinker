/** 
 Author: paniq
 Linear interpolation of eight cube corners by treating the cube as a composite of two tetrahedra and one octahedron. Press P to change the cutting plane.
 */

#define shaderName a_Cube_10

#include "Common.h" 

struct InputBuffer {};

initialize() {}


class shaderName {
  
public:
  
  float2 m;
  float time;
  uint2 key;
  
  //------------------------------------------------------------------------
  // Camera
  //
  // Move the camera. In this case it's using time and the mouse position
  // to orbitate the camera around the origin of the world (0,0,0), where
  // the yellow sphere is.
  //------------------------------------------------------------------------
  void doCamera( thread float3& camPos, thread float3& camTar, float time, float mouseX )
  {
    float an = 0.3*time;
    float d = 3.0;
    camPos = float3(d*sin(an),1.2,d*cos(an));
    camTar = float3(0.0,0.0,0.0);
  }
  
  //------------------------------------------------------------------------
  // Background
  //
  // The background color. In this case it's just a black color.
  //------------------------------------------------------------------------
  float3 doBackground( void )
  {
    return float3( 0.0, 0.0, 0.0);
  }
  
  float cubex(float3 p, float r) {
    float3 o = abs(p);
    float s = o.x;
    s = max(s, o.y);
    s = max(s, o.z);
    return s-r;
  }
  
  float sdf_round_box(float3 p, float3 b, float r) {
    return length(max(abs(p)-b,0.0))-r;
  }
  
  float2 min2(float2 a, float2 b) {
    return (a.x <= b.x)?a:b;
  }
  
  float2 max2(float2 a, float2 b) {
    return (a.x > b.x)?a:b;
  }
  
  float doModel( float3 p ) {
    
    float mouse_delta = saturate(m.x)*2.0-1.0;
    float plane = p.y  + mouse_delta;
    if ( key.x == 'p') {
      plane = ((p.x+p.y+p.z) + mouse_delta)/sqrt(3.0);
      plane = abs(plane)-0.01;
    }
    
    return max(cubex(p,1.0), plane);
    
  }
  
  //------------------------------------------------------------------------
  // Material
  //
  // Defines the material (colors, shading, pattern, texturing) of the model
  // at every point based on its position and normal. In this case, it simply
  // returns a constant yellow color.
  //------------------------------------------------------------------------
  
  float3 hue2rgb(float hue) {
    return clamp(
                 abs(mod(hue * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
                 0.0, 1.0);
  }
  
  float gray(float3 color) {
    return dot(float3(1.0/3.0), color);
  }
  
  // given three factors in the range (0..1), return the eight interpolants
  // -xyzw, +xyzw required to mix the corners of a cube
  void trilinear_interpolants( float3 p, thread float4& s, thread float4& t) {
    float3 q = 1.0 - p;
    
    float2 h = float2(q.x,p.x);
    float4 k = float4(h*q.y, h*p.y);
    s = k * q.z;
    t = k * p.z;
  }
  
  // given three interpolants (0..1) within a tet-oct-tet cube, return the
  // weights required for interpolation.
  void fcc_interpolants(float3 x, thread float4& a, thread float4& b) {
    float q = x.x+x.y+x.z;
    if (q < 1.0) {
      a = float4(1.0-q,x.x,x.y,0.0);
      b = float4(x.z, 0.0, 0.0, 0.0);
    } else if (q < 2.0) {
      float3 t = x.yzx + x.zxy - 1.0;
      float d = (1.0 - (abs(t.x)+abs(t.y)+abs(t.z)))/6.0;
      float3 u = d+max(-t,0.0);
      float3 v = d+max(t,0.0);
      a = float4(0.0, u.x, u.y, v.z);
      b = float4(u.z, v.y, v.x, 0.0);
    } else {
      float3 t = 1.0-x;
      a = float4(0.0, 0.0, 0.0, t.z);
      b = float4(0.0, t.y, t.x, q-2.0);
    }
  }
  
  float3 doMaterial( float3 pos, float3 nor )
  {
    // color cube with components swapped
    // to bring out the discontinuities
    const float3 c0 = float3(1.0,1.0,0.0);
    const float3 c1 = float3(0.0,1.0,0.0);
    const float3 c2 = float3(1.0,0.0,0.0);
    const float3 c3 = float3(0.0,0.0,0.0);
    const float3 c4 = float3(1.0,1.0,1.0);
    const float3 c5 = float3(1.0,0.0,1.0);
    const float3 c6 = float3(0.0,1.0,1.0);
    const float3 c7 = float3(0.0,0.0,1.0);
    
    pos = float3(pos.x, -pos.z, pos.y);
    
    float4 s,t;
    float3 col = float3(0.0);
    
    float3 p = pos*0.5+0.5;
    
    //trilinear_interpolants(p, s, t);
    fcc_interpolants(p,s,t);
    
    col = c0*s.x + c1*s.y + c2*s.z + c3*s.w
    + c4*t.x + c5*t.y + c6*t.z + c7*t.w;
    
    if ( key.x == 'c' ) {
      return hue2rgb(gray(col)*4.0);
    } else {
      return col;
    }
  }
  
  float calcIntersection( float3 ro, float3 rd )
  {
    const float maxd = 20.0;           // max trace distance
    const float precis = 0.001;        // precission of the intersection
    float h = precis*2.0;
    float t = 0.0;
    float res = -1.0;
    for( int i=0; i<90; i++ )          // max number of raymarching iterations is 90
    {
      if( h<precis||t>maxd ) break;
      h = doModel( ro+rd*t );
      t += h;
    }
    
    if( t<maxd ) res = t;
    return res;
  }
  
  float3 calcNormal( float3 pos )
  {
    const float eps = 0.002;             // precision of the normal computation
    
    const float3 v1 = float3( 1.0,-1.0,-1.0);
    const float3 v2 = float3(-1.0,-1.0, 1.0);
    const float3 v3 = float3(-1.0, 1.0,-1.0);
    const float3 v4 = float3( 1.0, 1.0, 1.0);
    
    return normalize( v1*doModel( pos + v1*eps ) +
                     v2*doModel( pos + v2*eps ) +
                     v3*doModel( pos + v3*eps ) +
                     v4*doModel( pos + v4*eps ) );
  }
  
  float3x3 calcLookAtMatrix( float3 ro, float3 ta, float roll )
  {
    float3 ww = normalize( ta - ro );
    float3 uu = normalize( cross(ww,float3(sin(roll),cos(roll),0.0) ) );
    float3 vv = normalize( cross(uu,ww));
    return float3x3( uu, vv, ww );
  }
};


fragmentFn() {
  shaderName shad;
  shad.time = uni.iTime;
  shad.key = uni.keyPress.xy;
  
  float2 p = worldCoordAspectAdjusted;
  shad.m = uni.iMouse.xy ;
  
  //-----------------------------------------------------
  // camera
  //-----------------------------------------------------
  
  // camera movement
  float3 ro, ta;
  shad.doCamera( ro, ta, uni.iTime, shad.m.x );
  
  // camera matrix
  float3x3 camMat = shad.calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
  
  // create view ray
  float3 rd = normalize( camMat * float3(p.xy,2.0) ); // 2.0 is the lens length
  
  //-----------------------------------------------------
  // render
  //-----------------------------------------------------
  
  float3 col = shad.doBackground();
  
  // raymarch
  float t = shad.calcIntersection( ro, rd );
  if( t>-0.5 )
  {
    // geometry
    float3 pos = ro + t*rd;
    float3 nor = shad.calcNormal(pos);
    
    col = shad.doMaterial( pos, nor );
  }
  
  return float4( col, 1.0 );
}

