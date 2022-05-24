/** 
 Author: paniq
 A method for linear interpolation of four tetrahedral corners that regresses to simple barycentric interpolation on the faces; drag the mouse for a cutaway; hit P to toggle the cutting plane. Hit N to toggle nearest neighbor interpolation.
 */

#define shaderName tetrahedral_interpolation

#include "Common.h" 

struct InputBuffer {};
initialize() {}


// see doMaterial for the interpolation routine

class shaderName {
public:

  // float2 m;
  uint2 key;
  float time;

  /*bool ReadKey( int key )//, bool toggle )
   {
   bool toggle = true;
   float keyVal = texture( iChannel3, float2( (float(key)+.5)/256.0, toggle?.75:.25 ) ).x;
   return (keyVal>.5)?true:false;
   }*/

  //------------------------------------------------------------------------
  // Camera
  //
  // Move the camera. In this case it's using time and the mouse position
  // to orbitate the camera around the origin of the world (0,0,0), where
  // the yellow sphere is.
  //------------------------------------------------------------------------
  void doCamera( thread float3& camPos, thread float3& camTar, float time )
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

  float tetrahedron(float3 p, float r) {
    float3 o = p / sqrt(3.0);
    float p1 = -o.x+o.y-o.z;
    float p2 =  o.x-o.y-o.z;
    float p3 = -o.x-o.y+o.z;
    float p4 =  o.x+o.y+o.z;
    float s = max(max(max(p1,p2),p3),p4);

    return s-r*1.0/sqrt(3.0);
  }

  float octahedron(float3 p, float r) {
    float3 o = abs(p) / sqrt(3.0);
    float s = o.x+o.y+o.z;
    return s-r*2.0/sqrt(3.0);
  }

  float doModel( float3 p ) {

    //  float mouse_delta = saturate(m.x)*2.0-1.0;
    float plane = p.y; // + mouse_delta;
    if ( key.x == 'p') {
      plane = ((p.x+p.y+p.z) /* + mouse_delta */)/sqrt(3.0);
      plane = abs(plane)-0.01;
    }

    return max(tetrahedron(p,0.5), plane);

  }

  //------------------------------------------------------------------------
  // Material
  //
  // Defines the material (colors, shading, pattern, texturing) of the model
  // at every point based on its position and normal. In this case, it simply
  // returns a constant yellow color.
  //------------------------------------------------------------------------

  float4 max4(float4 a, float4 b) {
    return (a.w > b.w)?a:b;
  }

  float2 max4(float2 a, float2 b) {
    return (a.y > b.y)?a:b;
  }

  float3 doMaterial( float3 pos, float3 nor )
  {
    const float3 c0 = float3(1.0,0.0,0.0);
    const float3 c1 = float3(0.0,1.0,0.0);
    const float3 c2 = float3(0.0,0.0,1.0);
    const float3 c3 = float3(1.0,1.0,0.0);

    pos = float3(pos.x, -pos.z, pos.y);
    if (max(pos.x,max(pos.y,pos.z)) > 1.01)
      return float3(0.0);

    float4 edge = float4((pos.yxz - pos.zyx - pos.xzy)*0.5+0.25, 0.0);
    edge.w = 1.0-edge.x-edge.y-edge.z;

    float3 col = float3(0.0);

    if ( key.x == 'n' ) {
      edge = floor(1.0+edge-max(max(edge.yzwx,edge.zwxy),edge.wxyz));
    }

    col = c0*edge.x + c1*edge.y + c2*edge.z + c3*edge.w;

    return col;
  }

  float calcIntersection(  float3 ro, float3 rd )
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
  // shad.m = uni.iMouse.xy;
  
  //-----------------------------------------------------
  // camera
  //-----------------------------------------------------
  
  // camera movement
  float3 ro, ta;
  shad.doCamera( ro, ta, uni.iTime /* shad.m.x */ );
  
  // camera matrix
  float3x3 camMat = shad.calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
  
  // create view ray
  float3 rd = normalize( camMat * float3(p.xy,2.0) ); // 2.0 is the lens length
  
  //-----------------------------------------------------
  // render
  //-----------------------------------------------------
  
  //  float3 col = shad.doBackground();
  
  // raymarch
  float t = shad.calcIntersection( ro, rd );
  if( t>-0.5 )
  {
    // geometry
    float3 pos = ro + t*rd;
    float3 nor = shad.calcNormal(pos);
    
    return float4( shad.doMaterial( pos, nor ), 1);
  } else {
    return 0;
  }

}
