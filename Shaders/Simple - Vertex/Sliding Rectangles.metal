
#define shaderName Sliding_Rectangles

#include "Common.h"

/* in a pipeline definition, the first elemnet is the "type".  4 is triangle strip, 3 is triangle.   -1 is compute, 0 is point, 1 is line
 the second number is number of vertices.   The third number is number of instances.  The fourth is reserved for flags.
 */
struct InputBuffer {
  float4 clearColor = 0;
  struct {
    int4 _1;
  } pipeline;
};
initialize() {
  in.clearColor = {0, 0, 0, 1};
  in.pipeline._1 = {4, 6, 6, 0};  // 6 squares
}

vertexPass(_1) {
  VertexOut v;
  v.color = 1; // white
  v.where.z = 0;
  v.where.w = 1;
  v.where.x = 2 * step( float(vid), 1) - 1;
  v.where.y = 1-2*fmod(float(vid), 2);  // square


  float tf = 2.1;

  // There are 8 movements.
  float z = 3 * uni.iTime;  // speed
  int mv = int(z) % 8; // which movement
  float pc = fract(z);   // percent of meovement

  // after 6 movements, we're back to the beginning
  int cy = (int(z) / 8) % 6;
  // v.color.r = iid / 6.;

  int aid = (iid + cy) % 6;

  // there are 6 squares which are located in a 3x3 grid.
  // So first, I figure out which grid position the instance should be in.

  int g;
  float2 os = 0;

  // translate to position:
  switch (aid) {
    case 0:
      g = 1 - (mv > 0) ;
      os.x = float(mv == 0) * - pc;
      os.y = float(mv == 7) * - pc;
      break;
    case 1:
      g = 3 + (mv > 6);
      os.x = float(mv == 6) * pc;
      break;
    case 2:
      g = 4 - (3 * (mv > 1));
      os.y = float(mv == 1) * pc;
      break;
    case 3:
      g = 5 + (3 * (mv > 4));
      os.y = float(mv == 4) * - pc;
      break;
    case 4:
      g = 7 - (3 * (mv > 2)) + (mv > 5);
      os.y = float(mv == 2) * pc;
      os.x = float(mv == 5) * pc;
      break;
    case 5:
      g = 8 - (mv > 3);
      os.x = float(mv == 3) * -pc;
      break;
  }

  int2 xy = int2(g % 3, g / 3) - 1;
  xy.y = -xy.y;

  v.where.xy += float2(xy) * 2.1;
  v.where.xy += os * tf;

  float scale =  1 / ( tf * sqrt(2.) * (uni.iResolution.x / uni.iResolution.y));
  v.where.xy *= scale; // 0.1928473039599675; // square size

  v.where.xy = v.where.xy * rot2d( - PI / 4); // rotate 45 degrees

  //  float2 translate = float2(-cos(uni.iTime),sin(uni.iTime));

  v.where.y *= uni.iResolution.x / uni.iResolution.y; // aspect ratio
  return v; 
}


/*
 static float r(float2 p, float2 U, float2 reso) {
 float2 s = reso.y/8.* max( .96 - abs( (p-U-U)*float2x2(1,1,1,-1) ), 0.);
 return min(s.x,s.y);
 }

 // #define P          float2(2,1) - abs( float2( --T%8-4, T%4-1 ) )
 //#define P ( T--, float2(2,1) - abs( float2(   T%8-4, T%4-1 ) )  )

 fragmentFn() {
 float4 fragColor = 0;
 float2 U = ( thisVertex.where.xy+thisVertex.where.xy - uni.iResolution )/uni.iResolution.y ;
 int  T = int( fragColor.a = 5.*uni.iTime ), S=T;
 T -= 1;
 float2 p0 = float2(2,1) - abs( float2( T%8-4, T%4-1 ) ) ;
 T -= 1;
 float2 p1 = float2(2,1) - abs( float2( T%8-4, T%4-1 ) ) ;
 fragColor += r( mix( p0, p1, fract(fragColor.a)), U, uni.iResolution ) - r(0, U, uni.iResolution);
 for ( T+=8; T>S; ) {
 T -= 1;
 float2 pp = float2(2,1) - abs( float2( T%8-4, T%4-1 ) );
 fragColor += r(pp, U, uni.iResolution);
 }
 return fragColor;
 }
 */
