
#define shaderName meshify

#include "Common.h" 

#define L 8.  // interline distance
#define A 4.  // amplification factor
#define P 6.  // thickness

fragmentFunc(texture2d<float> tex) {
  float4 o = 0;
  float2 uv = thisVertex.where.xy / L;
  float2  p = floor(uv+.5);

#define T(x,y) tex.sample(iChannel0,L*float2(x,y) * scn_frame.inverseResolution).g   // add .g or nothing

#define M(c,T) o += pow(.5+.5*cos( TAU*(uv-p).c + A*(2.*T-1.) ),P)

  M( y, T( uv.x, p.y ) );   // modulates  y offset
  M( x, T( p.x, uv.y ) );   // modulates  y offset
  return o;
}
