/** 
 Author: kjfung
 Path traces a Julia Set with Monte Carlo integration

 Done mostly using information from http://blog.hvidtfeldts.net/index.php/2015/01/path-tracing-3d-fractals/
 */

#define shaderName monte_carlo_julia_set

#include "Common.h" 

struct KBuffer {
};
initialize() {}

#define N float(uni.iFrame)
#define SPHERE_SIZE 75.0
#define COLOR float3(1.0)
#define T 37.5
#define FRAC_ITER 10
#define c float4(-0.137,-0.630,-0.475,-0.046)

// Shamelessly stolen from iq's fractal demo
// ???? What is a cosine ¿¿¿¿
float3 cosineDirection( const float seed, const float3 nor)
{
  float3 tc = float3( 1.0+nor.z-nor.xy*nor.xy, -nor.x*nor.y)/(1.0+nor.z);
  float3 uu = float3( tc.x, tc.z, -nor.x );
  float3 vv = float3( tc.z, tc.y, -nor.y );

  float u = rand( 78.233 + seed);
  float v = rand( 10.873 + seed);
  float a = TAU * v;

  return  sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
}

float4 qSquare(float4 a)
{
  return float4(a.x*a.x - dot(a.yzw,a.yzw), 2.0*a.x*(a.yzw));
}

float distToScene(float3 p) {
  float4 f = float4(p, 0.0);
  float fp2 = 1.0;
  for (int i = 0; i < FRAC_ITER; i++)
  {
    fp2 *= 4.0 * dot(f,f);
    f = qSquare(f) + c;
    if (dot(f,f) > 4.0)
      break;
  }

  float r = length(f);
  float julia = 0.5 * log(r) * (r/sqrt(fp2));

  float4 n = float4(0.0, 1.0, 0.0, 1.0);
  float plane = dot(p,n.xyz) + n.w;

  return min(plane, julia);
}

bool rayMarch(float3 eye, float3 dir, thread float3& p, thread float3& nor)
{
  p = eye + dir;
  float d = distToScene(p);
  float3  e = float3(0.0005, 0.0, 0.0);

  for(int i = 0; i < 256; i++)
  {
    if(d <= e.x)
    {
      nor = normalize(float3(distToScene(p + e.xyy) - d,
                             distToScene(p + e.yxy) - d,
                             distToScene(p + e.yyx) - d));
      return true;
    }
    p = p + d * normalize(dir);
    d = distToScene(p);
  }

  nor = float3(0.0);
  return false;
}

float3 primaryRay(float2 pxCoord, thread float3& eye, const float time, const float2 reso)
{
  eye = float3(3.0 * sin(T), 0.0, 3.0 * cos(T));
  float focal = 500.0;
  float3 up = float3(0.0, 1.0, 0.0);
  float3 focus = float3(0.0, 0.0, 0.0);

  // Perturb the pixel a little bit
  pxCoord.x += (rand(pxCoord + time) - 0.5);
  pxCoord.y += (rand(pxCoord.yx + time) - 0.5);

  //Calculate eye directions
  float3 look = focus - eye;
  float3 right = cross(look, up);

  //Calculate this particular pixel's normalized coordinates
  //on the virtual screen
  float screenX = (2.0 * pxCoord.x)/(1.0 * reso.x) - 1.0;
  float screenY = (2.0 * pxCoord.y)/(1.0 * reso.y) - 1.0;

  //Calculate the direction that the ray through this pixel goes
  float3 dir = normalize(focal * normalize(look)
                         + screenX * normalize(right) * reso.x/2.0
                         + screenY * normalize(up) * reso.y/2.0);
  return dir;
}



fragmentFn1() {
  FragmentOutput fff;
  fff.fragColor = renderInput[0].read(uint2(thisVertex.where.xy));

  // ============================================== buffers =============================
  float2 uv = thisVertex.where.xy / uni.iResolution.xy;

  // Create primary ray
  float3 eye;
  float3 dir = primaryRay(thisVertex.where.xy, eye, uni.iTime, uni.iResolution);

  float3 f = float3(0.0);
  float3 lum = float3(1.0);
  float3 p, nor;
  for (int i = 0; i < 2; i++)
  {
    if (rayMarch(eye, dir, p, nor))
    {
      eye = p + 0.1 * nor;
      dir = cosineDirection(rand(uv + uni.iTime), nor);
      lum *= 2.0 * 0.5 * dot(dir, nor);
    }
    else
    {
      f = lum * COLOR;
    }
  }

  float4 oldValue = renderInput[0].sample(iChannel0, uv);
  fff.pass1 = ((oldValue * N) + float4(f, 1.0)) / (N + 1.0);
  return fff;
}
