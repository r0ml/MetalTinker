/** 
 Author: reinder
 These shaders are my implementation of the ray/path tracer described in the book "Raytracing in one weekend" by Peter Shirley. I have tried to follow the code from his book as much as possible.
 */

// Raytracing in one weekend, chapter 7: Diffuse. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/llVcDz
//
// These shaders are my implementation of the raytracer described in the (excellent) 
// book "Raytracing in one weekend" [1] by Peter Shirley (@Peter_shirley). I have tried 
// to follow the code from his book as much as possible, but I had to make some changes 
// to get it running in a fragment shader:
//
// - There are no classes (and methods) in glsl so I use structs and functions instead. 
//   Inheritance is implemented by adding a type variable to the struct and adding ugly 
//   if/else statements to the (not so overloaded) functions.
// - The scene description is procedurally implemented in the world_hit function to save
//   memory.
// - The color function is implemented using a loop because it is not possible to have a 
//   recursive function call in glsl.
// - Only one sample per pixel per frame is calculated. Samples of all frames are added 
//   in Buffer A and averaged in the Image tab.
//
// You can find the raytracer / pathtracer in Buffer A.
//
// = Ray tracing in one week =
// Chapter  7: Diffuse                           https://www.shadertoy.com/view/llVcDz
// Chapter  9: Dielectrics                       https://www.shadertoy.com/view/MlVcDz
// Chapter 11: Defocus blur                      https://www.shadertoy.com/view/XlGcWh
// Chapter 12: Where next?                       https://www.shadertoy.com/view/XlycWh
//
// = Ray tracing: the next week =
// Chapter  6: Rectangles and lights             https://www.shadertoy.com/view/4tGcWD
// Chapter  7: Instances                         https://www.shadertoy.com/view/XlGcWD
// Chapter  8: Volumes                           https://www.shadertoy.com/view/XtyyDD
// Chapter  9: A Scene Testing All New Features  https://www.shadertoy.com/view/MtycDD
//
// [1] http://in1weekend.blogspot.com/2016/01/ray-tracing-in-one-weekend.html
//

#define shaderName riow_107_diffuse

#include "Common.h" 

struct KBuffer { };

initialize() {}



// ============================================== buffers =============================

// Raytracing in one weekend, chapter 7: Diffuse. Created by Reinder Nijhoff 2018
// @reindernijhoff
//
// https://www.shadertoy.com/view/llVcDz
//
// These shaders are my implementation of the raytracer described in the (excellent) 
// book "Raytracing in one weekend" [1] by Peter Shirley (@Peter_shirley). I have tried 
// to follow the code from his book as much as possible.
//
// [1] http://in1weekend.blogspot.com/2016/01/ray-tracing-in-one-weekend.html
//

#define MAX_FLOAT 1e5
#define MAX_RECURSION 5

//
// Hash functions by Nimitz:
// https://www.shadertoy.com/view/Xt3cDn
//

uint base_hash(uint2 p) {
  p = 1103515245U*((p >> 1U)^(p.yx));
  uint h32 = 1103515245U*((p.x)^(p.y>>3U));
  return h32^(h32 >> 16);
}


float2 hash2(thread float& seed) {
  seed += .2;
  uint n = base_hash(uint2(as_type<uint>(seed - .1),as_type<uint>(seed)));
  uint2 rz = uint2(n, n*48271U);
  return float2(rz.xy & uint2(0x7fffffffU))/float(0x7fffffff);
}

float3 hash3(thread float& seed) {
  seed += 0.2;
  uint n = base_hash( uint2(as_type<uint>(seed - .1),as_type<uint>(seed)));
  uint3 rz = uint3(n, n*16807U, n*48271U);
  return float3(rz & uint3(0x7fffffffU))/float(0x7fffffff);
}

//
// Ray trace helper functions
//

float schlick(float cosine, float ior) {
  float r0 = (1.-ior)/(1.+ior);
  r0 = r0*r0;
  return r0 + (1.-r0)*pow((1.-cosine),5.);
}

float3 random_in_unit_sphere(thread float& seed) {
  float3 h = hash3(seed) * float3(2.,TAU,1.)-float3(1,0,0);
  float phi = h.y;
  float r = pow(h.z, 1./3.);
  return r * float3(sqrt(1.-h.x*h.x)*float2(sin(phi),cos(phi)),h.x);
}

//
// Ray
//

struct ray {
  float3 origin, direction;
};

//
// Hit record
//

struct hit_record {
  float t;
  float3 p, normal;
};

//
// Hitable, for now this is always a sphere
//

struct hitable {
  float3 center;
  float radius;
};

bool hitable_hit(const hitable hb, const ray r, const float t_min,
                 const float t_max, thread hit_record& rec) {
  // always a sphere
  float3 oc = r.origin - hb.center;
  float b = dot(oc, r.direction);
  float c = dot(oc, oc) - hb.radius * hb.radius;
  float discriminant = b * b - c;
  if (discriminant < 0.0) return false;

  float s = sqrt(discriminant);
  float t1 = -b - s;
  float t2 = -b + s;

  float t = t1 < t_min ? t2 : t1;
  if (t < t_max && t > t_min) {
    rec.t = t;
    rec.p = r.origin + t*r.direction;
    rec.normal = (rec.p - hb.center) / hb.radius;
    return true;
  } else {
    return false;
  }
}

//
// Camera
//

struct camera {
  float3 origin, lower_left_corner, horizontal, vertical;
};

ray camera_get_ray(camera c, float2 uv) {
  return ray { c.origin,
    normalize(c.lower_left_corner + uv.x*c.horizontal + uv.y*c.vertical - c.origin) } ;
}

//
// Color & Scene
//

bool world_hit(const ray r, const float t_min, const float t_max, thread hit_record& rec) {
  rec.t = t_max;
  bool hit = false;

  hit = hitable_hit(hitable { float3(0,0,-1), .5 } , r, t_min, rec.t, rec) || hit;
  hit = hitable_hit(hitable { float3(0,-100.5,-1),100. } , r, t_min, rec.t, rec) || hit;

  return hit;
}

float3 color(ray r, thread float& g_seed) {
  float3 col = float3(1);
  hit_record rec;

  for (int i=0; i<MAX_RECURSION; i++) {
    if (world_hit(r, 0.001, MAX_FLOAT, rec)) {
      float3 rd = normalize(rec.normal + random_in_unit_sphere(g_seed));
      col *= .5;

      r.origin = rec.p;
      r.direction = rd;
    } else {
      float t = .5*r.direction.y + .5;
      col *= mix(float3(1),float3(.5,.7,1), t);
      return col;
    }
  }
  return col;
}

//
// Main
//


fragmentFn1() {
  FragmentOutput fff;
  float g_seed = 0.;
  float4 data = texelFetch(renderInput[0], int2(thisVertex.where.xy),0);
  fff.fragColor = float4(sqrt(data.rgb/data.w),1.0);

  if ( all(int2(thisVertex.where.xy) == int2(0)))  {
    fff.pass1 = uni.iResolution.xyxy;
  } else {
    g_seed = float(base_hash( uint2(as_type<uint>(thisVertex.where.x), as_type<uint>(thisVertex.where.y))))/float(0xffffffffU)+uni.iTime;

    float2 uv = (thisVertex.where.xy + hash2(g_seed))/uni.iResolution.xy;
    float aspect = uni.iResolution.x/uni.iResolution.y;

    ray r = camera_get_ray(camera { float3(0), float3(-2,-1,-1), float3(4,0,0), float3(0,4./aspect,0 ) } , uv);
    float3 col = color(r, g_seed);

    if ( all(texelFetch(renderInput[0], int2(0),0).xy == uni.iResolution ) ) {
      fff.pass1 = float4(col,1) + texelFetch(renderInput[0], int2(thisVertex.where.xy), 0);
    } else {
      fff.pass1 = float4(col,1);
    }
  }
  return fff;
}
