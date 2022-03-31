
#define shaderName physics_no_collisions

#include "Common.h" 

struct InputBuffer {
};
initialize() {}

static float2  hash2( float p ) { float2 q = float2( p, p+123.123 ); return fract(sin(q)*43758.5453); }
static float3  hash3( float n ) { return fract(sin(float3(n,n+1.0,n+2.0))*43758.5453123); }

// draw a disk with motion blur
static float3 diskWithMotionBlur( float3 col, float2 uv, float3 sph, float2 cd, float3 sphcol, float alpha )
{
  float2 xc = uv - sph.xy;
  float a = dot(cd,cd);
  float b = dot(cd,xc);
  float c = dot(xc,xc) - sph.z*sph.z;
  float h = b*b - a*c;
  if( h>0.0 )
  {
    h = sqrt( h );

    float ta = max( 0.0, (-b - h)/a );
    float tb = min( 1.0, (-b + h)/a );

    if( ta < tb ) // we can comment this conditional, in fact
      col = mix( col, sphcol, alpha*saturate(2.0*(tb-ta)) );
  }

  return col;
}

static float2 GetPos( float2 p, float2 v, float2 a, float t )
{
  return p + v*t + 0.5*a*t*t;
}
static float2 GetVel( float2 p, float2 v, float2 a, float t )
{
  return v + a*t;
}

// intersect a disk moving in a parabolic trajecgory with a line/plane. 
// sphere is |x(t)|-RÂ²=0, with x(t) = p + vÂ·t + Â½Â·aÂ·tÂ²
// plane is <x,n> + k = 0
static float iPlane( float2 p, float2 v, float2 a, float rad, float3 pla )
{
  float A = dot(a,pla.xy);
  float B = dot(v,pla.xy);
  float C = dot(p,pla.xy) + pla.z - rad;
  float h = B*B - 2.0*A*C;
  if( h>0.0 )
    h = (-B-sqrt(h))/A;
  return h;
}

fragmentFn() {

  const float2 acc = float2(0.01,-9.0);
  float2 p = worldCoordAspectAdjusted;

  float w = uni.iResolution.x/uni.iResolution.y;

  float3 pla0 = float3( 0.0,1.0,1.0);
  float3 pla1 = float3(-1.0,0.0,  w);
  float3 pla2 = float3( 1.0,0.0,  w);

  float3 col = float3(0.0) + (0.15 + 0.05*p.y);

  for( int i=0; i<8; i++ )
  {
    // start position
    float id = float(i);

    float time = mod( uni.iTime + id*0.5, 4.8 );
    float sequ = floor( (uni.iTime+id*0.5)/4.8 );
    float life = time/4.8;

    float rad = 0.05 + 0.1*rand(id*13.0 + sequ);
    float2 pos = float2(-w,0.8) + float2(2.0*w,0.2)*hash2( id + sequ );
    float2 vel = (-1.0 + 2.0*hash2( id+13.76 + sequ ))*float2(8.0,1.0);

    // integrate
    float h = 0.0;
    // 10 bounces.
    // after the loop, pos and vel contain the position and velocity of the ball
    // after the last collision, and h contains the time since that collision.
    for( int j=0; j<10; j++ )
    {
      float ih = 100000.0;
      float2 nor = float2(0.0,1.0);

      // intersect planes
      float s;
      s = iPlane( pos, vel, acc, rad, pla0 ); if( s>0.0 && s<ih ) { ih=s; nor=pla0.xy; }
      s = iPlane( pos, vel, acc, rad, pla1 ); if( s>0.0 && s<ih ) { ih=s; nor=pla1.xy; }
      s = iPlane( pos, vel, acc, rad, pla2 ); if( s>0.0 && s<ih ) { ih=s; nor=pla2.xy; }

      if( ih<1000.0 && (h+ih)<time )
      {
        float2 npos = GetPos( pos, vel, acc, ih );
        float2 nvel = GetVel( pos, vel, acc, ih );
        pos = npos;
        vel = nvel;
        vel = 0.75*reflect( vel, nor );
        pos += 0.01*vel;
        h += ih;
      }
    }

    // last parabolic segment
    h = time - h;
    float2 npos = GetPos( pos, vel, acc, h );
    float2 nvel = GetVel( pos, vel, acc, h );
    pos = npos;
    vel = nvel;

    // render
    float3 scol = 0.5 + 0.5*sin( rand(id)*2.0 -1.0 + float3(0.0,2.0,4.0) );
    float alpha = smoothstep(0.0,0.1,life)-smoothstep(0.8,1.0,life);
    col = diskWithMotionBlur( col, p, float3(pos,rad), vel/24.0, scol, alpha );
  }

  col += (1.0/255.0)*hash3(p.x+13.0*p.y);

  return float4(col,1.0);
}

