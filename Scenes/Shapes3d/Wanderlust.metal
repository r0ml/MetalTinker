
#define shaderName wanderlust

#include "Common.h" 

struct InputBuffer {};
initialize() {}

struct ray { float3 origin; float3 direction; };

static ray cameraRay(float2 uv, float3 camera) {
  float2 pos = uv - 0.5;
  return ray { camera, float3(pos.x, pos.y, 1) };
}

static float3 intersectPlane(float planeHeight, ray r) {
  float height = planeHeight - r.origin.y;
  
  return r.origin + r.direction / r.direction.y * height;
}

static float3 stars(float3 direction) {
  return float3( step(0.0001, rand(direction) ) );
  //        return float3(0,0,0);
  //    else
  //        return float3(1,1,1);
}

static float3 checkered(float2 location) {
  return float3(  abs(step(1, mod(location.x, 2)) - step(1, mod(location.y, 2))) );
  /*
   if ((mod(location.x, 2.) > 1.) != (mod(location.y, 2.) > 1.))
   return float3(0,0,0);
   else
   return float3(1,1,1);
   */
}

static float3 foggy(float3 color, float d, float view) {
  float viewFactor = max(0., view / d);
  
  return color * viewFactor + float3(.5, .5, .5) * (1. - viewFactor);
}

static float3 traceColor(ray r) {
  float d;
  float3 color;
  
  if(r.direction.y >= 0.) {
    color = stars(r.direction);
    d = 50.;
  } else {
    float3 intersect = intersectPlane(0., r);
    d = length(r.origin - intersect);
    color = checkered(intersect.xz);
  }
  
  return foggy(color, d, r.origin.z * .1);
}

fragmentFn() {
  // Normalized pixel coordinates (from 0 to 1)
  float2 uv = textureCoord;
  uv.y = 1-uv.y;
  
  ray r = cameraRay(uv, float3(0,1,uni.iTime * uni.iTime));
  
  float3 col = traceColor(r);
  return float4(col,1.0);
}


