/** 
 Author: paniq
 Regular solids formed by intersections between cube, octahedron (the cube's dual) and rhombic dodecahedron, an interpolation of the cube and its dual. Uses IQ's 3D template.

 based on the 3D template by iq
 */
#define shaderName Archimedean_Solids

#include "Common.h"

struct InputBuffer { };

initialize() { }





// uncomment for a cross section view
//#define CROSS_SECTION

//------------------------------------------------------------------------
// Camera
//
// Move the camera. In this case it's using time and the mouse position
// to orbitate the camera around the origin of the world (0,0,0), where
// the yellow sphere is.
//------------------------------------------------------------------------
static void doCamera( thread float3& camPos, thread float3& camTar, const float time, const float mouseX )
{
#ifdef CROSS_SECTION
  float an = 1.5+sin(0.3*time);
#else
  float an = 0.3*time + 10.0*mouseX;
#endif
  camPos = float3(4.5*sin(an),2.0,4.5*cos(an));
  camTar = float3(0.0,0.0,0.0);
}


//------------------------------------------------------------------------
// Background 
//
// The background color. In this case it's just a black color.
//------------------------------------------------------------------------
static float3 doBackground( void )
{
  return float3( 0.0, 0.0, 0.0);
}

// all three basic bodies are symmetric across the XYZ planes
// octahedron and rhombic dodecahedron have been scaled to align
// with the vertices of the cube.

// 1D distance of X Y Z planes
static float2 cubex(float3 p, float r) {
  float3 o = abs(p);
  float s = o.x;
  s = max(s, o.y);
  s = max(s, o.z);
  return float2(s-r, 0.0);
}

// 3D distance of XYZ cross diagonal plane
static float2 octahedron(float3 p, float r) {
  float3 o = abs(p) / sqrt(3.0);
  float s = o.x+o.y+o.z;
  return float2(s-r*2.0/sqrt(3.0), 1.0);
}

// 2D distance of XY YZ ZX diagonal planes
static float2 rhombic(float3 p, float r) {
  float3 o = abs(p) / sqrt(2.0);
  float s = o.x+o.y;
  s = max(s, o.y+o.z);
  s = max(s, o.z+o.x);
  return float2(
                s-r*sqrt(2.0),
                2.0);
}

static float2 min2(float2 a, float2 b) {
  return (a.x <= b.x)?a:b;
}

static float2 max2(float2 a, float2 b) {
  return (a.x > b.x)?a:b;
}

#define SHAPE_COUNT 8.0
static float3 get_factors(int i) {
  if (i == 0) {
    // cube
    return float3(1.0, 6.0/4.0, 1.0);
  } else if (i == 1) {
    // truncated cube
    return float3(1.0, 6.0/5.0, 1.0);
  } else if (i == 2) {
    // cuboctahedron
    return float3(1.0, 1.0, 1.0);
  } else if (i == 3) {
    // truncated octahedron
    return float3(4.0/3.0, 1.0, 1.0);
  } else if (i == 4) {
    // truncated cuboctahedron
    return float3(sqrt(3.0/2.0), 2.0/sqrt(3.0), 1.0);
  } else if (i == 5) {
    // rhombicuboctahedron
    return float3(sqrt(2.0), sqrt(5.0/3.0), 1.0);
  } else if (i == 6) {
    // octahedron
    return float3(2.0, 1.0, 1.0);
  }
  return float3(0.0);
}

static float2 plane( float3 p) {
  return float2(p.y+2.0,3.0);
}

//------------------------------------------------------------------------
// Modelling 
//
// Defines the shapes (a sphere const this case) through a distance field, in
// this case it's a sphere of radius 1.
//------------------------------------------------------------------------
static float2 add_plane(float3 p, float2 m) {
#ifdef CROSS_SECTION
  m.x = max(max(m.x, p.x),-m.x-0.2);
#endif
  return min2(plane(p),m);
}

static float2 doModel( float3 p , float time) {
  float k = time*0.5;
  //k = 1.0;
  float u = smoothstep(0.0,1.0,smoothstep(0.0,1.0,fract(k)));
  int s1 = int(mod(k,SHAPE_COUNT));
  int s2 = int(mod(k+1.0,SHAPE_COUNT));
  if (s1 == 6) {
    return add_plane(p, mix(octahedron(p, 1.0), rhombic(p, 1.0), u));
  } else if (s1 == 7) {
    return add_plane(p, mix(rhombic(p, 1.0), cubex(p, 1.0), u));
  } else {
    float3 f = mix(get_factors(s1),
                   get_factors(s2), u);
    return add_plane(p, max2(max2(cubex(p,f.x),octahedron(p, f.y)), rhombic(p, f.z)));
  }
  
}

//------------------------------------------------------------------------
// Material 
//
// Defines the material (colors, shading, pattern, texturing) of the model
// at every point based on its position and normal. In this case, it simply
// returns a constant yellow color.
//------------------------------------------------------------------------
static float3 doMaterial( const float3 pos, const float3 nor, float time )
{
  float k = doModel(pos, time).y;
  return mix(mix(mix(float3(1.0,0.07,0.01),float3(0.2,1.0,0.01),saturate(k)),
                 float3(0.1,0.07,1.0),
                 saturate(k-1.0)),
             float3(0.1),
             saturate(k-2.0));
}

static float calcSoftshadow( const float3 ro, const float3 rd, float time )
{
  float res = 1.0;
  float t = 0.0005;                 // selfintersection avoidance distance
  float h = 1.0;
  for( int i=0; i<40; i++ )         // 40 is the max numnber of raymarching steps
  {
    h = doModel(ro + rd*t, time).x;
    res = min( res, 64.0*h/t );   // 64 is the hardness of the shadows
    t += clamp( h, 0.02, 2.0 );   // limit the max and mconst stepping distances
  }
  return saturate(res);
}

//------------------------------------------------------------------------
// Lighting
//------------------------------------------------------------------------

static float3 doLighting( const float3 pos, const float3 nor, const float3 rd, const float dis, const float3 mal, float time )
{
  float3 lin = float3(0.0);

  // key light
  //-----------------------------
  float3  lig = normalize(float3(1.0,0.7,0.9));
  float dif = dot(nor,lig) * 0.5 + 0.5;
  float sha = 0.0; if( dif>0.01 ) sha=calcSoftshadow( pos+0.01*nor, lig, time );
  lin += dif;


  // surface-light interacion
  //-----------------------------
  float3 col = mal*lin;


  // fog
  //-----------------------------
  col *= exp(-0.01*dis*dis);

  return col;
}

static float calcIntersection( const float3 ro, const float3 rd, float time )
{
  const float maxd = 20.0;           // max trace distance
  const float precis = 0.001;        // precission of the intersection
  float h = precis*2.0;
  float t = 0.0;
  float res = -1.0;
  for( int i=0; i<90; i++ )          // max number of raymarching iterations is 90
  {
    if( h<precis||t>maxd ) break;
    h = doModel( ro+rd*t , time ).x;
    t += h;
  }

  if( t<maxd ) res = t;
  return res;
}

static float3 calcNormal( const float3 pos, float time )
{
  const float eps = 0.002;             // precision of the normal computation

  const float3 v1 = float3( 1.0,-1.0,-1.0);
  const float3 v2 = float3(-1.0,-1.0, 1.0);
  const float3 v3 = float3(-1.0, 1.0,-1.0);
  const float3 v4 = float3( 1.0, 1.0, 1.0);

  return normalize( v1*doModel( pos + v1*eps, time ).x +
                   v2*doModel( pos + v2*eps , time).x +
                   v3*doModel( pos + v3*eps , time).x +
                   v4*doModel( pos + v4*eps , time).x );
}


static float3x3 calcLookAtMatrix( const float3 ro, const float3 ta, const float roll )
{
  float3 ww = normalize( ta - ro );
  float3 uu = normalize( cross(ww,float3(sin(roll),cos(roll),0.0) ) );
  float3 vv = normalize( cross(uu,ww));
  return float3x3( uu, vv, ww );
}

fragmentFn()
{
  float2 p = worldCoordAspectAdjusted;

  float2 m = uni.iMouse.xy;

  //-----------------------------------------------------
  // camera
  //-----------------------------------------------------

  // camera movement
  float3 ro, ta;
  doCamera( ro, ta, uni.iTime, m.x );

  // camera matrix
  float3x3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll

  // create view ray
  float3 rd = normalize( camMat * float3(p.xy,2.0) ); // 2.0 is the lens length

  //-----------------------------------------------------
  // render
  //-----------------------------------------------------

  float3 col = doBackground();

  // raymarch
  float t = calcIntersection( ro, rd , uni.iTime);
  if( t>-0.5 )
  {
    // geometry
    float3 pos = ro + t*rd;
    float3 nor = calcNormal(pos, uni.iTime);

    // materials
    float3 mal = doMaterial( pos, nor , uni.iTime);

    col = doLighting( pos, nor, rd, t, mal , uni.iTime);
  }

  //-----------------------------------------------------
  // postprocessing
  //-----------------------------------------------------
  // gamma
  col = pow( saturate(col), float3(0.4545) );

  return float4( col, 1.0 );
}
