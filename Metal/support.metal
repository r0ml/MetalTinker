//  Copyright © 1887 Sherlock Holmes. All rights reserved.
//  Found amongst his effects by r0ml

// so Common.h won't complain
#define shaderName not_used
#include "Common.h"

#include <metal_stdlib>
using namespace metal;

/*
 void stringSet(device string& lval, uint nv, const char val[]) {
 for(unsigned int i = 0;i < nv; i++) {
 lval.name[i]=val[i];
 }
 }
 */

void stringCopy(device string& lval, uint nv, thread char *val) {
  for(unsigned int i = 0;i < nv; i++) {
    lval.name[i]=val[i];
  }
}

/** calculate xy size of texture */
float2 textureSize(texture2d<float> t) {
  return float2(t.get_width(), t.get_height());
}

fragment float4 passthruFragmentFn( VertexOut thisVertex [[stage_in]] ) {
  return thisVertex.color;
}

vertex VertexOut flatVertexFn( uint vid [[ vertex_id ]] ) {
  VertexOut v;
  v.barrio.x = step( float(vid), 1);

//  v.barrio.y = 1-fmod(float(vid), 2);
  v.barrio.y = fmod(float(vid), 2);

  v.where.xy = 2 * v.barrio.xy - 1;
  v.where.y = - v.where.y;

  v.where.zw = {0, 1};
  
  v.color = 0; // then it works like it used to....
  return v;
}

// =====================================================

float fix_atan2(float y, float x) {
  if (x == 0) { return M_PI_F / (y < 0 ? -2 : 2); }
  if (y == 0) { return M_PI_F * (x < 0 ? -1 : 0); }
  return atan2(y, x);
}

// this is the PAL/NTSC algorithm for converting rgb to grayscale
float grayscale(float3 rgb) {
  return dot(float3(0.299, 0.587, 0.114),rgb);
}

float luminance(float3 rgb) {
  return dot(float3(0.2126, 0.7152, 0.0722), rgb);
}

static constant float eps = 0.0000001;

float3 rgb2hsv(float3 c) {
  float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
  float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
  float d = q.x - min(q.w, q.y);
  return float3(abs(q.z + (q.w - q.y) / (6.0 * d + eps)), d / (q.x + eps), q.x);
}

float3 hsv2rgb(const float3 c) {
  float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, saturate(p - K.xxx), c.y);
}

float3 gammaEncode(float3 c) {
  return pow(c, float3(1.0 / 2.2));
}

float4 gammaEncode(float4 c) {
  return float4(pow(c.rgb, float3(1.0 / 2.2)), c.a);
}

float3 gammaDecode(float3 c) {
  return pow(c, 2.2);
}

float4 gammaDecode(float4 c) {
  return float4(pow(c.rgb, 2.2), c.a);
}

float2x2 rot2d(float t) {
  float c, s = sincos(t, c);
  return float2x2(c, s, -s, c);
}

float2x2 rot2dpi(float t) {
  float c = cospi(t), s = sinpi(t);
  return float2x2(c, -s, s, c);
}

// Rotation matrix from angle-axis
float3x3 rotate( float3 axis, float angle) {
  float3x3 K = float3x3(0, axis.z, -axis.y,   -axis.z, 0, axis.x,    axis.y, -axis.x, 0);
  return float3x3(1.0) + K*(float3x3(sin(angle)) + (1.0-cos(angle))*K);
}

// rotate about x axis
float3x3 rotX( float angle) {
  float cx = cos(angle), sx = sin(angle);
  return float3x3(1., 0, 0,      0, cx, sx,      0, -sx, cx);
}

// rotate about y axis
float3x3 rotY( float angle) {
  float cy = cos(angle), sy = sin(angle);
  return float3x3(cy, 0, -sy,    0, 1., 0,       sy, 0, cy);
}

// rotate about z axis
float3x3 rotZ(float angle) {
  float cz = cos(angle), sz = sin(angle);
  return float3x3(cz, -sz, 0.,   sz, cz,0.,      0.,0.,1.);
}





float2x2 makeMat(float4 x) {
  return float2x2(x.x, x.y, x.z, x.w);
}

namespace global {
  constant uint KEY_LEFT  = 0xf702;
  constant uint KEY_UP    = 0xf700;
  constant uint KEY_RIGHT = 0xf703;
  constant uint KEY_DOWN  = 0xf701;
  
  constant float epsilon = 0.000001;
  constant float tau = 2 * M_PI_F;
  constant float TAU = 2 * M_PI_F;
  constant float pi = M_PI_F;
  constant float PI = M_PI_F;
  constant float e = M_E_F;
  constant float E = M_E_F;
  constant float phi = 1.6180339887498948482; // sqrt(5.0)*0.5 + 0.5;
  constant float PHI = 1.6180339887498948482; // sqrt(5.0)*0.5 + 0.5;
  constant float goldenRatio = phi;
}

// ==============================================================================
// Useful functions
// ==============================================================================

float3 flux(float x) {
  return float3(cos(x),cos(4.0*M_PI_F/3.0+x),cos(2.0*M_PI_F/3.0+x))*.5+.5;
}

float3 phase(float map) {
  return acos(2 * flux(map)-1);
}

float cross( float2 a, float2 b ) { return a.x*b.y - a.y*b.x; }

// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
float3 tex3d( const texture2d<float> tex, const float3 pp, const float3 nn ) {
  // float3 n = max((abs(nn) - .2)*7., .001);
  // alternative is:
  float3 n = max(abs(nn), 0.001);
  n /= (n.x + n.y + n.z );
  float3 p = (  tex.sample(iChannel0, pp.yz)*n.x
              + tex.sample(iChannel0, pp.zx)*n.y
              + tex.sample(iChannel0, pp.xy)*n.z).xyz;
  return p*p;
}

// - Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total
float3 doBumpMap(const texture2d<float> txx, const float3 p, const float3 n, float bf){
  
  const float2 e = float2(0.001, 0);
  
  // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.
  float3x3 m = float3x3(tex3d(txx, p - e.xyy, n),
                        tex3d(txx, p - e.yxy, n),
                        tex3d(txx, p - e.yyx, n));
  
  float3 g = float3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
  g = (g - grayscale(tex3d(txx, p , n)) )/e.x;
  g -= n*dot(n, g);
  
  return normalize( n + g*bf ); // Bumped normal. bf = bump factor.
  
}


// ============================================================
// random numbers
// ============================================================
float4 rand4(float2 x) {
  float G = e;
  float2 r = (G * sin(G * x));
  return abs(float4( fract(r.x * r.y * (PHI + x.x)),
                    fract(sin(r.x * r.y * (PI+x.y))),
                    fract( dot(r,r) * cos( dot(x, e))),
                    fract( pow(r.y,r.x+1) * atan2( r.x, r.y))
                    ));
}

float3 rand3(float2 winCoord, float tim) {
  float3 v = float3(winCoord, tim);
  v = fract(v) + fract(v*10000) + fract(v*0.0001);
  v += float3(0.12345, 0.6789, 0.314159);
  v = fract(v*dot(v, v)*123.456);
  v = fract(v*dot(v, v)*123.456);
  return v;
}

float2 rand2(float2 x) {
  float3 y = fract(cos(x.xyx) * float3(.1031, .1030, .0973));
  y += dot(y, y.yzx+19.19);
  return abs(fract((y.x+y.yz)*y.zy));
}

// ======================================================

/*void neighborhood(texture2d<float> t, uint2 xco, float3 uv[5]) {
  uint2 rr = uint2(t.get_width(), t.get_height());
  uv[0] = t.read( xco ).xyz;
  uv[1] = t.read( (xco + uint2(0, 1)) % rr).xyz;  // up
  uv[2] = t.read( (xco + uint2(1, 0)) % rr).xyz;  // right
  uv[3] = t.read( (xco + uint2(0, rr.y-1)) % rr).xyz;  // down
  uv[4] = t.read( (xco + uint2(rr.x - 1, 0)) % rr).xyz; // left
}*/

void neighborhood(texture2d<float> t, uint2 xco, thread float3 uv[9]) {
  uint2 rr = uint2(t.get_width(), t.get_height());
  uv[0] = t.read( (xco + rr - 1) % rr).xyz;
  uv[1] = t.read( (xco + uint2(0, rr.y-1)) % rr).xyz;
  uv[2] = t.read( (xco + uint2(1, rr.y-1)) % rr).xyz;
  uv[3] = t.read( (xco + uint2(rr.x - 1, 0)) % rr).xyz;
  uv[4] = t.read( xco ).xyz;
  uv[5] = t.read( (xco + uint2(1, 0)) % rr).xyz;
  uv[6] = t.read( (xco + uint2(rr.x-1 , 1)) % rr).xyz;
  uv[7] = t.read( (xco + uint2(0, 1)) % rr).xyz;
  uv[8] = t.read( (xco + 1) % rr).xyz;
}


void neighborhood(texture2d<float> t, uint2 xco, thread float3x3 op[4]) {
  uint2 rr = uint2(t.get_width(), t.get_height());
  for(int i=-1; i <= 1; i++) {
    for(int j = -1; j<= 1; j++) {
      float4 z = t.read( uint2(int2(xco) + int2(i,j) % int2(rr))  );
      op[0][i+1][j+1] = z.x;
      op[0][i+1][j+1] = z.y;
      op[0][i+1][j+1] = z.z;
      op[0][i+1][j+1] = z.w;
    }
  }
}

float convolve(float3x3 a, float3x3 b) {
  return a[0][0]*b[0][0]+
  a[0][1]*b[0][1]+
  a[0][2]*b[0][2]+
  a[1][0]*b[1][0]+
  a[1][1]*b[1][1]+
  a[1][2]*b[1][2]+
  a[2][0]*b[2][0]+
  a[2][1]*b[2][1]+
  a[2][1]*b[2][1]
  ;
}

/*
 constant float2x2 bayer2 = { 0, 2, 3, 1};
 constant float3x3 bayer3 = {0,7,3,6,5,2,4,1,8};
 constant float4x4 bayer4 = {0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5};
 constant float bayer8[8][8] = {
 {0, 48, 12, 60 ,3, 51, 15, 63},
 {32, 16, 44, 28, 35, 19, 47, 31},
 {8, 56, 4, 52, 11, 59, 7, 55},
 {40, 24, 36, 20, 43, 27, 39, 23},
 { 2, 50, 14, 62,  1, 49, 13, 61},
 {34, 18, 46, 30, 33, 17, 45, 29},
 {10, 58,  6, 54,  9, 57,  5, 53},
 {42, 26, 38, 22, 41, 25, 37, 21}
 };
 
 */

float4 prand4(float2 x, float2 iResolution) {
  float2 x1 = floor(x * 512) / iResolution;
  float2 x2 = ceil(x * 512) / iResolution;
  float4 a1 = rand(x1);
  float4 a2 = rand(x2);
  float z = ((x * 512)/iResolution - x1).x;
  float zz = z / (x2.x - x1.x + (x2.x == x1.x));
  float4 T = mix( a1, a2, zz);
  return T;
}


// simulates getting random pixels from a noise texture.
// the algorithm interpolates between the random values at quantized distances from the requested position
// the second argument is the "granularity" of the virtual noise texture
float3 interporand(float2 pos, float reso) {
  float2 a = floor(pos * reso);
  float2 b = fract(pos * reso);
  
  float3 p1 = rand3(a/reso);
  float3 p2 = rand3((a + float2(0, 1)) / reso);
  float3 p3 = rand3((a + 1) / reso);
  float3 p4 = rand3((a + float2(1, 0)) / reso);

  float3 t1 = mix(p1, p4, b.x);
  float3 t2 = mix(p2, p3, b.x);
  float3 t3 = mix(t1, t2, b.y);
  return t3;
}


// ==========================================================

// smoothed minimum
// http://iquilezles.org/www/articles/smin/smin.htm
float polySmin( float a, float b, float k ) {
  float h = saturate( 0.5+0.5*(b-a)/k );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float polySmax( float a, float b, float k ) {
  float h = saturate( 0.5 + 0.5*(b-a)/k );
  return mix( a, b, h ) + k*h*(1.0-h);
}

// exponential smoothed minimum -- k should be negative (like -4)
float expSmin( float a, float b, float k ) {
  float res = exp( -k*a ) + exp( -k*b );
  return -log( res )/k;
}
float expSmax(float a, float b, float k) {
  return log(exp(k*a)+exp(k*b))/k;
}

// commutative smoothed minimum
float commSmin(float a, float b, float k) {
  float f = max(0., 1. - abs(b - a)/k);
  return min(a, b) - k*.25*f*f;
}
float commSmax( float a,  float b, float k) {
  float f = max(0., 1. - abs(b - a)/k);
  return max(a, b) + k*.25*f*f;
}

// =================================================

float2 PixToHex (float2 p) {
  float3 c;
  c.xz = float2 ((1./sqrt(3.)) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  float3 r = floor (c + 0.5);
  float3 dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, float3 (1.));
  return r.xz;
}

float2 HexToPix (float2 h) {
  return float2 (sqrt(3.) * (h.x + 0.5 * h.y), (3./2.) * h.y);
}

float3 HexGrid (float2 p) {
  p -= HexToPix (PixToHex (p));
  float2 q = abs (p);
  return float3 (p, 0.5 * sqrt(3.) - q.x + 0.5 * min (q.x - sqrt(3.) * q.y, 0.));
}

float HexEdgeDist (float2 p) {
  p = abs (p);
  return (sqrt(3.)/2.) - p.x + 0.5 * min (p.x - sqrt(3.) * p.y, 0.);
}

// ===================================================================

// return color from temperature
//http://www.physics.sfasu.edu/astro/color/blackbody.html
//http://www.vendian.org/mncharity/dir3/blackbody/
//http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html
float3 blackbody(float Temp) {
  float3 col = float3(255.);
  col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
  col.y = 100.04 * log(Temp) - 623.6;
  if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
  col.z = 194.18 * log(Temp) - 1448.6;
  col = clamp(col, 0., 255.)/255.;
  if (Temp < 1000.) col *= Temp/1000.;
  return col;
}

float3 BlackBody( float t ) {
    float h = 6.6e-34; // Planck constant
    float k = 1.4e-23; // Boltzmann constant
    float c = 3e8;// Speed of light

    float3 w = float3( 610.0, 549.0, 468.0 ) / 1e9; // sRGB approximate wavelength of primaries
    
    // This would be more accurate if we integrate over a range of wavelengths
    // rather than a single wavelength for r, g, b
    
    // Planck's law https://en.wikipedia.org/wiki/Planck%27s_law
    
    float3 w5 = w*w*w*w*w;
    float3 o = 2.*h*(c*c) / (w5 * (exp(h*c/(w*k*t)) - 1.0));

    return o;
}

// ========================================================================

// Vertex fns...

// this is a radial way of creating polygons -- at around 50 sides it's a circle
float3 polygon(uint vid, uint sides, float radius, float2 aspect) {
  uint tv = vid % 3;
  uint tn = vid / 3;
  float3 res = 0;
  switch(tv) {
    case 0:
      res.z = (float(tn) + 0.5) / float(sides);
      break;
    case 1:
      res.z = float(tn) / float(sides);
      res.xy = float2(radius, 0) * aspect * rot2d( res.z * TAU ) / aspect;
      break;
    case 2:
      res.z = float(tn + 1) / float(sides);
      res.xy = float2(radius, 0) * aspect * rot2d( res.z * TAU ) / aspect;
      break;
  }
  return res;
}

// centered at 0
float3 annulus(uint vid, uint sides, float inner, float outer, float2 aspect) {
  uint tv = vid % 6;
  uint tn = vid / 6;
  float3 res = 0;
  switch(tv) {
    case 0:
    case 4:
      res.z = 2 * float(tn + 0.5) / float(sides);
      res.xy = float2(outer, 0) * aspect * rot2d(res.z * TAU) / aspect;
      break;
    case 1:
      res.z = 2 * float(tn)     / float(sides); // this one is negative for tn = 0
      res.xy = float2(inner, 0) * aspect * rot2d( res.z * TAU ) / aspect;
      break;
    case 2:
    case 3:
      res.z = 2 * float(tn + 1) / float(sides);
      res.xy = float2(inner, 0) * aspect * rot2d( res.z * TAU) / aspect;
      break;
    case 5:
      res.z = 2 * float(tn + 1.5) / float(sides);
      res.xy = float2(outer, 0) * aspect * rot2d( res.z * TAU ) / aspect;
      break;
  }
  return res;
}


// centered at 0
float3 annulus(uint vid, uint sides, float inner, float outer, float2 aspect, float startAngle, float endAngle) {
  uint tv = vid % 6;
  uint tn = vid / 6;
  float3 res = 0;
  float subtend = endAngle - startAngle; // in radians -- default is TAU
  switch(tv) {
    case 0:
    case 4:
      res.z = startAngle + 2 * float(tn + 0.5) / float(sides) * subtend;
      res.xy = float2(outer, 0) * aspect * rot2d(res.z) / aspect;
      break;
    case 1:
      res.z = startAngle + 2 * float(tn)     / float(sides) * subtend; // this one is negative for tn = 0
      res.xy = float2(inner, 0) * aspect * rot2d( res.z) / aspect;
      break;
    case 2:
    case 3:
      res.z = startAngle + 2 * float(tn + 1) / float(sides) * subtend;
      res.xy = float2(inner, 0) * aspect * rot2d( res.z ) / aspect;
      break;
    case 5:
      res.z = startAngle + 2 * float(tn + 1.5) / float(sides) * subtend;
      res.xy = float2(outer, 0) * aspect * rot2d( res.z ) / aspect;
      break;
  }
  return res;
}



// ==============================================================

float rand( float n ) {
  return fract(sin(n)*43758.5453123);
}

// sometimes known as Hashfv2
// float2(127.1,311.7)
// float2(12.9898,78.233)
float rand( float2 n) {
  return fract (sin (dot (n, float2(12.9898,78.233))) * 43758.5453123);
}

// float3(283.6,127.1,311.7)
float rand( float3 n) {
  return fract(sin(dot(n ,float3(12.9898,78.233,12.7378))) * 43758.5453);
}

float noisePerlin(float p) {
  float i = floor (p);
  float f = fract (p);
  f = f * f * (3. - 2. * f);
  float2 t = fract(sin(i + float2(0, 1) * 43758.54));
  return mix (t.x, t.y, f);
}

float noisePerlin(float2 x) {
  float2 p = floor(x);
  float2 f = fract(x);
  f = f*f*(3.-2.*f);  // or smoothstep     // to make derivative continuous at borders
  return mix(mix(rand(p+float2(0,0)),
                 rand(p+float2(1,0)), f.x),       // triilinear interp
             mix(rand(p+float2(0,1)),
                 rand(p+float2(1,1)), f.x), f.y);
}

float noisePerlin(float3 x) {
  float3 p = floor(x);
  float3 f = fract(x);
  f = f*f*(3.-2.*f);  // or smoothstep     // to make derivative continuous at borders
  return mix(mix(mix(rand(p+float3(0,0,0)),
                     rand(p+float3(1,0,0)), f.x),       // triilinear interp
                 mix(rand(p+float3(0,1,0)),
                     rand(p+float3(1,1,0)), f.x), f.y),
             mix(mix(rand(p+float3(0,0,1)),
                     rand(p+float3(1,0,1)), f.x),
                 mix(rand(p+float3(0,1,1)),
                     rand(p+float3(1,1,1)), f.x), f.y), f.z);
}






// also known as Hashv4f
float4 hash4( float n) {
  return fract (sin (n + float4 (0., 1., 57., 58.)) * 43758.5453123);
}

// -------------------------------------------------------------------
// Colors

Color palette( float t, Color a, Color b, Color c, Color d ) {
  return a + b*cos( tau*(c*t+d) );
}

float vignette( float2 uv, float p) {
  return pow(uv.x * uv.y * (1-uv.x) * (1-uv.y), p);
}

// Normalized Device Coordinate given Viewport coordinate and Viewport size
float2 ndc(float2 vc, float2 res) {
  float2 uv = 2. * vc / res - 1.;
  uv.x *= res.x / res.y;
  uv.y = -uv.y;
  return uv;
}
