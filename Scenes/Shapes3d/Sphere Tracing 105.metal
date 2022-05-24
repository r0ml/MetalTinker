/** 
 Author: fab
 To go along with the corresponding blog post which can be found here: http://fabricecastel.github.io/blog/2016-08-17/main.html
 */
#define shaderName Sphere_Tracing_105

#include "Common.h"

struct InputBuffer { };
initialize() {}






// ray computation vars
constant const float fov = 50.0;

// epsilon-type values
constant const float S = 0.01;
constant const float EPSILON = 0.01;

// const delta vectors for normal calculation
constant const float3 deltax = float3(S ,0, 0);
constant const float3 deltay = float3(0 ,S, 0);
constant const float3 deltaz = float3(0 ,0, S);

static float distanceToNearestSurface(float3 p){
  float3 q = float3(mod(p.x, 3.0) - 1.5, p.yz);
  float s = 1.0;
  float3 d = abs(q) - float3(s);
  return min(max(d.x, max(d.y,d.z)), 0.0)
  + length(max(d,0.0));
}


// better normal implementation with half the sample points
// used in the blog post method
static float3 computeSurfaceNormal(float3 p){
  float d = distanceToNearestSurface(p);
  return normalize(float3(
                          distanceToNearestSurface(p+deltax)-d,
                          distanceToNearestSurface(p+deltay)-d,
                          distanceToNearestSurface(p+deltaz)-d
                          ));
}


static float3 computeLambert(float3 p, float3 n, float3 l){
  return float3(dot(normalize(l-p), n));
}

static float3 intersectWithWorld(float3 p, float3 dir, float time){
  float dist = 0.0;
  float nearest = 0.0;
  float3 result = float3(0.0);
  for(int i = 0; i < 40; i++){
    nearest = distanceToNearestSurface(p + dir*dist);
    if(nearest < EPSILON){
      float3 hit = p+dir*dist;
      float3 light = float3(100.0*sin(time), 30.0, 50.0*cos(time));
      result = computeLambert(hit, computeSurfaceNormal(hit), light);
      break;
    }
    dist += nearest;
  }
  return result;
}

fragmentFn()
{
  float2 uv = textureCoord;
  
  //   float cameraDistance = 10.0;
  float3 cameraPosition = float3(10.0*sin(uni.iTime), 2.0, 10.0*cos(uni.iTime));
  float3 cameraDirection = normalize(float3(-1.0*sin(uni.iTime), -0.2, -1.0*cos(uni.iTime)));
  float3 cameraUp = float3(0.0, 1.0, 0.0);
  
  // generate the ray for this pixel
  const float fovx = PI * fov / 360.0;
  float fovy = fovx * uni.iResolution.y/uni.iResolution.x;
  const float ulen = tan(fovx);
  float vlen = tan(fovy);
  
  float2 camUV = uv*2.0 - float2(1.0, 1.0);
  float3 nright = normalize(cross(cameraUp, cameraDirection));
  float3 pixel = cameraPosition + cameraDirection + nright*camUV.x*ulen + cameraUp*camUV.y*vlen;
  float3 rayDirection = normalize(pixel - cameraPosition);
  
  float3 pixelColour = intersectWithWorld(cameraPosition, rayDirection, uni.iTime);
  return float4(pixelColour, 1.0);
}
