/** 
 Author: faof
 shader oui
 */


#define shaderName zizou

#include "Common.h" 

struct InputBuffer { };

initialize() {}

static constant int Steps = 1000;
static constant float Epsilon = 0.05; // Marching epsilon
static constant float T=0.5;

static constant float rA=10.0; // Maximum ray marching or sphere tracing distance from origin
static constant float rB=40.0; // Minimum

 


// Transforms
/*static float3 rotateX(float3 p, float a)
{
  float sa = sin(a);
  float ca = cos(a);
  return float3(p.x, ca*p.y - sa*p.z, sa*p.y + ca*p.z);
}*/

static float3 rotateY(float3 p, float a)
{
  float sa = sin(a);
  float ca = cos(a);
  return float3(ca*p.x + sa*p.z, p.y, -sa*p.x + ca*p.z);
}
/*
static float3 rotateZ(float3 p, float a)
{
  float sa = sin(a);
  float ca = cos(a);
  return float3(ca*p.x + sa*p.y, -sa*p.x + ca*p.y, p.z);
}*/


// Smooth falloff function
// r : small radius
// R : Large radius
static float falloff( float r, float R )
{
  float x = saturate(r/R);
  float y = (1.0-x*x);
  return y*y*y;
}

// Primitive functions

// Point skeleton
// p : point
// c : center of skeleton
// e : energy associated to skeleton
// R : large radius
static float point(float3 p, float3 c, float e,float R)
{
  return e*falloff(length(p-c),R);
}


static float segment(float3 p, float3 a, float3 b, float e, float r){
  float3 pa = p - a, ba = b - a;
  float h = saturate( dot(pa,ba)/dot(ba,ba));
  return e*falloff(length( pa - ba*h ),r);
}


// Blending
// a : field function of left sub-tree
// b : field function of right sub-tree
static float Blend(float a,float b)
{
  return a+b;
}

// Union
// a : field function of left sub-tree
// b : field function of right sub-tree
/*static float Union(float a,float b)
{
  return max(a,b);
}*/

// Potential field of the object
// p : point
static float object(float3 p)
{
  p.z=-p.z;
  float v = Blend(point(p,float3( 0.0, 1.0, 1.0),1.0,4.5),
                  segment(p,float3( 2.0, 0.0,-3.0),float3( 12.0, 0.0,-3.0),1.0,2.0));
  return v-T;
}

// Calculate object normal
// p : point
static float3 ObjectNormal(float3 p )
{
  float eps = 0.0001;
  float3 n;
  float v = object(p);
  n.x = object( float3(p.x+eps, p.y, p.z) ) - v;
  n.y = object( float3(p.x, p.y+eps, p.z) ) - v;
  n.z = object( float3(p.x, p.y, p.z+eps) ) - v;
  return normalize(n);
}

// Trace ray using ray marching
// o : ray origin
// u : ray direction
// h : hit
// s : Number of steps
/*static float Trace(float3 o, float3 u, thread bool& h, thread int& s)
{
  h = false;
  
  // Don't start at the origin, instead move a little bit forward
  float t=rA;
  
  for(int i=0; i<Steps; i++)
  {
    s=i;
    float3 p = o+t*u;
    float v = object(p);
    // Hit object
    if (v > 0.0)
    {
      s=i;
      h = true;
      break;
    }
    // Move along ray
    t += Epsilon;
    // Escape marched far away
    if (t>rB)
    {
      break;
    }
  }
  return t;
}*/

// Trace ray using ray marching
// o : ray origin
// u : ray direction
// h : hit
// s : Number of steps
static float SphereTrace(float3 o, float3 u, thread bool& h, thread int& s)
{
  h = false;
  
  // Don't start at the origin, instead move a little bit forward
  float t=rA;
  
  for(int i=0; i<Steps; i++)
  {
    s=i;
    float3 p = o+t*u;
    float v = object(p);
    // Hit object
    if (v > 0.0)
    {
      s=i;
      h = true;
      break;
    }
    // Move along ray
    t += max(Epsilon,abs(v)/4.0);
    // Escape marched far away
    if (t>rB)
    {
      break;
    }
  }
  return t;
}


// Background color
static float3 background(float3 rd)
{
  return mix(float3(0.4, 0.3, 0.0), float3(0.7, 0.8, 1.0), rd.y*0.5+0.5);
}

// Shading and lighting
// p : point,
// n : normal at point
static float3 Shade(float3 p, float3 n)
{
  // point light
  const float3 lightPos = float3(5.0, 5.0, 5.0);
  const float3 lightColor = float3(0.5, 0.5, 0.5);
  
  float3 c = 0.25*background(n);
  float3 l = normalize(lightPos - p);
  
  // Not even Phong shading, use weighted cosine instead for smooth transitions
  float diff = 0.5*(1.0+dot(n, l));
  
  c += diff*lightColor;
  
  return c;
}

// Shading with number of steps
/*static float3 ShadeSteps(int n)
{
  float t=float(n)/(float(Steps-1));
  return float3(t,0.25+0.75*t,0.5-0.5*t);
}*/


fragmentFn() {
  float2 pixel = worldCoordAspectAdjusted;
  
  // compute ray origin and direction
  float3 rd = normalize(float3(pixel, -4.0));
  float3 ro = float3(0.0, 0.0, 20.0);
  
  // float2 mouse = uni.iMouse.xy / uni.iResolution.xy;
  float a=uni.iTime*0.25;
  ro = rotateY(ro, a);
  rd = rotateY(rd, a);
  
  // Trace ray
  bool hit;
  
  // Number of steps
  int s;
  
  float t = SphereTrace(ro, rd, hit,s);
  float3 pos=ro+t*rd;
  // Shade background
  float3 rgb = background(rd);
  
  if (hit)
  {
    // Compute normal
    float3 n = ObjectNormal(pos);
    
    // Shade object with light
    rgb = Shade(pos, n);
  }
  
  // Uncomment this line to shade image with false colors representing the number of steps
  //rgb = ShadeSteps(s);
  
  return float4(rgb, 1.0);
}

