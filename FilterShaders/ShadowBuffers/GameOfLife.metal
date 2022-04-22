/** 
 Author: iq
 Conway's Game of Life [url]http://www.iquilezles.org/www/articles/gameoflife/gameoflife.htm[/url]. Buffer A contains the world and it reads/writes to itself to perform the simulation. I implemented 3 variants
 */
#define shaderName GameOfLife

#include "Common.h"

// Conway's Game of Life - http://www.iquilezles.org/www/articles/gameoflife/gameoflife.htm
//
// State based simulation. Buffer A contains the simulated world, and it reads and writes to
// itself to perform the simulation.
//
// I implemented three variants of the algorithm with different interpretations

// VARIANT = 0: traditional
// VARIANT = 1: box fiter
// VARIANT = 2: high pass filter

#define VARIANT 0


static int Cell( texture2d<float> inTexture, int2 p )
{
  // do wrapping
  int2 r = int2(textureSize(inTexture));
  p = (p+r) % r;
  
  // fetch texel
  return (texelFetch(inTexture, p, 0 ).x > 0.5 ) ? 1 : 0;
}

static float hash1( float n )
{
  return fract(sin(n)*138.5453123);
}


fragmentFn(texture2d<float> lastFrame) {

  int2 px = int2( thisVertex.where.xy );
  
#if VARIANT==0
  int k =
  Cell(lastFrame, px+int2(-1,-1)) +
  Cell(lastFrame, px+int2(0,-1)) +
  Cell(lastFrame, px+int2(1,-1)) +
  Cell(lastFrame, px+int2(-1, 0)) +
  Cell(lastFrame, px+int2(1, 0)) +
  Cell(lastFrame, px+int2(-1, 1)) +
  Cell(lastFrame, px+int2(0, 1)) +
  Cell(lastFrame, px+int2(1, 1));
  
  int e = Cell(lastFrame, px);
  
  float f = ( ((k==2)&&(e==1)) || (k==3) ) ? 1.0 : 0.0;
  
#endif
  
#if VARIANT==1
  int k = Cell(px+int2(-1,-1)) + Cell(px+int2(0,-1)) + Cell(px+int2(1,-1))
  + Cell(px+int2(-1, 0)) + Cell(px            ) + Cell(px+int2(1, 0))
  + Cell(px+int2(-1, 1)) + Cell(px+int2(0, 1)) + Cell(px+int2(1, 1));
  
  int e = Cell(px);
  
  float f = ( ((k==4)&&(e==1)) || (k==3) ) ? 1.0 : 0.0;
  
#endif
  
  
#if VARIANT==2
  int k = -Cell(px+int2(-1,-1)) -   Cell(px+int2(0,-1)) - Cell(px+int2(1,-1))
  -Cell(px+int2(-1, 0)) + 8*Cell(px)           - Cell(px+int2(1, 0))
  -Cell(px+int2(-1, 1)) -   Cell(px+int2(0, 1)) - Cell(px+int2(1, 1));
  
  float f = (abs(k+3)*abs(2*k-11)<=9) ? 1.0 : 0.0;
  
  
#endif
  
  if( uni.iFrame==0 ) f = step(0.5, hash1(thisVertex.where.x*13.0+hash1(thisVertex.where.y*71.1)));
  
  return float4( f, 0.0, 0.0, 0.0 );
}
