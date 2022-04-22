/** 
Author: tehsauce
Scattering function is not physically accurate, but efficiently shifts a random direction towards the normal to create a hemisphere. 
*/

#define shaderName minimal_pathtracer

#include "Common.h" 

struct KBuffer {
};


initialize() {}



// ============================================= common =================================

// This enables/disables the pretty but
// expensive background wall

//#define FUN_WALL

// These delays can be used to switch to
// to fullscreen before accumulation begins
#ifdef FUN_WALL
#define DELAY 10
#else
#define DELAY 30
#endif

constant float3 box_size = float3(3.0,1.0,3.0);
constant float4 spherePos = float4( 0.0,-0.4,1.8, 0.4);
// constant float3 sphereCol = float3( 1.0, 0.4, 0.6 );
// constant float wiggle = 1.0;

static float hash1( uint n )
{
  // integer hash copied from Hugo Elias
  n = (n << 13U) ^ n;
  n = n * (n * n * 15731U + 789221U) + 1376312589U;
  return float( n & uint(0x7fffffffU))/float(0x7fffffff);
}

#define MOD3 float3(.1031,.11369,.13787)
static float hash31(float3 p3)
{
  p3  = fract(p3 * MOD3);
  p3 += dot(p3, p3.yzx + 19.19);
  return -1.0 + 2.0 * fract((p3.x + p3.y) * p3.z);
}

#ifdef FUN_WALL
static float3 hash33(float3 p3)
{
  p3 = fract(p3 * MOD3);
  p3 += dot(p3, p3.yxz+19.19);
  return -1.0 + 2.0 *
  fract(float3((p3.x + p3.y)*p3.z,
             (p3.x+p3.z)*p3.y,
             (p3.y+p3.z)*p3.x));
}

static float simplex_noise(float3 p)
{
  const float K1 = 0.333333333;
  const float K2 = 0.166666667;

  float3 i = floor(p + (p.x + p.y + p.z) * K1);
  float3 d0 = p - (i - (i.x + i.y + i.z) * K2);

  // thx nikita: https://www.shadertoy.com/view/XsX3zB
  float3 e = step(float3(0.0), d0 - d0.yzx);
  float3 i1 = e * (1.0 - e.zxy);
  float3 i2 = 1.0 - e.zxy * (1.0 - e);

  float3 d1 = d0 - (i1 - 1.0 * K2);
  float3 d2 = d0 - (i2 - 2.0 * K2);
  float3 d3 = d0 - (1.0 - 3.0 * K2);

  float4 h = max(0.6 - float4(dot(d0, d0), dot(d1, d1),
                          dot(d2, d2), dot(d3, d3)), 0.0);
  float4 n = h * h * h * h * float4(dot(d0, hash33(i)),
                                dot(d1, hash33(i + i1)),
                                dot(d2, hash33(i + i2)),
                                dot(d3, hash33(i + 1.0)));

  return dot(float4(31.316), n);
}

static float noise_sum_abs(float3 p)
{
  float f = 0.0;
  p = p * 3.0;
  f += 1.0000 * abs(simplex_noise(p)); p = 2.0 * p;
  f += 0.5000 * abs(simplex_noise(p)); p = 2.0 * p;
  f += 0.2500 * abs(simplex_noise(p)); p = 2.0 * p;
  f += 0.1250 * abs(simplex_noise(p)); p = 2.0 * p;
  f += 0.0625 * abs(simplex_noise(p)); p = 2.0 * p;

  return f;
}

static float noise_sum_abs_sin(float3 p)
{
  float f = noise_sum_abs(p);
  f = sin(f * 2.5 + p.x * 5.0 - 1.5);

  return f ;
}
#endif

static float hash71( float3 p, float3 dir, int t) {
  float a = hash1( uint(t) );
  float b = hash31(p);
  float c = hash31(dir);
  return hash31(float3(a,b,c));
}

// from https://math.stackexchange.com/questions/44689/how-to-find-a-random-axis-or-unit-vector-in-3d
static float3 randomDir( float3 p, float3 dir, int t) {
  float a = hash1( uint(t) );
  float b = hash31(p);
  float c = hash31(dir);
  float theta = tau*hash31(float3(a,b,c));
  float z = 2.0*hash31(
                       float3( c+1.0, 2.0*a+3.5, b*1.56+9.0 ) ) - 1.0;
  float m = sqrt(1.0-z*z);
  return float3( m*sin(theta), m*cos(theta), z );
}



static float sdBoxx( float3 p, float3 b )
{
#ifdef FUN_WALL
  if (p.z>1.45 && abs(p.x) < 2.7){
    p.z +=
    0.25*(smoothstep(2.7, 1.5, abs(p.x)))
    *noise_sum_abs_sin(0.3*p);
  }
#endif
  float3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0)
  + length(max(d,0.0));
}

/*static float sdSphereReg( float3 p, float s )
{
  return length(p)-s;
}*/

static float sdSpherex( float3 p, float s )
{
  p.x *= 0.3;
  return length(p+float3(0.0,0.2*sin(15.0*p.x),0.0))-s;
}

static float map( float3 p) {
  float d = 1000000.0;
  d = min( d, sdSpherex(p-spherePos.xyz, spherePos.w));
  d = min( d, -sdBoxx( p, box_size ) );
  return d;
}

static float3 calcNormal( const float3 pos )
{
  float2 e = float2(1.0,-1.0)*0.5773*0.0005;
  return normalize( e.xyy*map( pos + e.xyy ) +
                   e.yyx*map( pos + e.yyx ) +
                   e.yxy*map( pos + e.yxy ) +
                   e.xxx*map( pos + e.xxx ) );
}




// ===========================================================================================================


static float3 boxCol( float3 p )
{
    float3 c = float3( 0.9, 0.9, 0.9);
    if (p.x>box_size.x-0.001) {
        c.rb = float2(0.0);
    }
    if (p.x<-box_size.x+0.001) {
        c.rg = float2(0.0);
    }
  return c;
}

static void intersect( thread float3& ray_pos, float3 ray_dir)
{
    float thresh = 0.0002;
    float d;
    for (int i=0; i<96; i++)
    {
       d = map(ray_pos);
        if (d<thresh) {
          break;
        }
        ray_pos += ray_dir*d*0.4;
    }
}

 



fragmentFn1() {
  FragmentOutput fff;

    // Normalized pixel coordinates (from 0 to 1)
    float2 uvx = thisVertex.where.xy/uni.iResolution.xy;

    float3 colx = renderInput[0].sample( iChannel0, uvx).rgb;

    // Output to screen
    fff.fragColor = float4(colx,1.0);

 // ============================================== buffers ============================= 

    float2 uvt = thisVertex.where.xy/uni.iResolution.xy;
    float2 uv = uvt - 0.5;
    uv.x *= uni.iResolution.x/uni.iResolution.y;
    
    // Jitter pixel start coordinates for free antialiasing 
    float2 p_size = 2.0/uni.iResolution.xy;
    uv.x += p_size.x*hash1( uint( 10000.0*uni.iTime ) );
    uv.y += p_size.y*hash1( uint( 20000.0*uni.iTime+3535.0 ) );
    float3 ray_dir = normalize(float3(uv, 1.0));
    float3 ray_pos = float3(0.0, 0.0, -1.0);
    float3 col = float3(1.0,1.0,1.0);
    
    float3 incoming = float3(0.0);
    
	for (int b=0; b<6; b++)
    {
    	intersect(ray_pos, ray_dir);
        
        float3 n = calcNormal(ray_pos);

        if (sdSpherex(ray_pos-spherePos.xyz,
            spherePos.w) < 0.01) {
         // hit sphere
            float3 c = float3(sin(4.0*ray_pos.x)+1.0, 0.2, 0.5);
       		col *= c;
            incoming += 0.03*c;
        } else if (
            	ray_pos.y > 0.99 &&
            	all( ( mod( abs(ray_pos.xz+float2(4.4,0.0)), 1.5 ) < float2(1.3) ) ) ) {
           	// hit ceiling           
            incoming += float3(5.0);
            break;
        } else {
            // hit walls or floor
            col *= boxCol(ray_pos);
            incoming += float3(0.01);
        }
        
		float perp = length(cross(n,ray_dir));
        float rand = hash71(ray_pos, ray_dir, uni.iFrame);
        if (rand > 0.9-0.7*perp*perp*perp) {
            // specular reflection
        	ray_dir = reflect(ray_dir, n);
        } else {
            // diffuse scatter
         	float3 ndir = randomDir( ray_pos, ray_dir, uni.iFrame+10 );
            ray_dir = normalize(8.0*(ndir+n*1.002));
        }
        ray_pos += 0.01*ray_dir;
    }
    
	col = incoming*col;

    // adjust color space
    col = pow(col, float3(0.44));

    // delay accumulation to allow time for full screen
    float m = 1.0-1.0/float(uni.iFrame-DELAY);
    if (uni.iFrame < DELAY+1) m = 0.0;
    //m = 0.99;
    float3 prev = renderInput[0].sample( iChannel0, uvt).rgb;
    fff.pass1 = float4(mix(col,prev,m), 1.0);
  return fff;
}
