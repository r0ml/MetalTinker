/** 
 Author: danb
 I saw a gif and just wanted to make a shader of it. Code is far from being nice or efficient, but i don't care... ^_^
 [url]http://gph.is/2vGZBdt[/url]
 */
#define shaderName a_Cube_8

#include "Common.h"

struct InputBuffer { };
initialize() {}



static float box(float3 pos, float3 size)
{
  return length(max(abs(pos) - size, 0.0));
}

static float wave_model(float phi)
{
  phi = mod(phi, 4.0 * pi);
  
  return   phi <= pi / 2. ? phi
  : phi <= 2. * pi ? pi / 2.
  : phi <= 5.0 * pi / 2. ? pi / 2. - (phi - 2. * pi)
  : 0.;
}

static float distfunc(float3 pos, float time)
{
  float t = time * 2.0;
  float cube_dist_param = 0.21;
  float cube_size = 0.1;
  float scale = 0.75;

  float last_dist = 10000.0;
  for (float i = -1.0; i < 2.0; i += 1.0)
  {
    for (float j = -1.0; j < 2.0; j += 1.0)
    {
      for (float k = -1.0; k < 2.0; k += 1.0)
      {
        float a = smoothstep(0.0, 1.0, wave_model(t + pi / 2.0)) * cube_dist_param + 0.2;
        float b = smoothstep(0.0, 1.0, wave_model(t + pi)) * cube_dist_param + 0.2;
        float c = smoothstep(0.0, 1.0, wave_model(t)) * cube_dist_param + 0.2;
        float3 rotpos = pos;
        rotpos.yz = rotpos.yz * rot2d(-pi / 5.0);
        rotpos.xz = rotpos.xz * rot2d(pi / 4.0);
        float next_dist = box(rotpos + float3(i * a, j * b, k * c), float3(cube_size)) * scale;
        last_dist = min(last_dist, next_dist);
      }
    }
  }
  
  return last_dist;
}

fragmentFn()
{
  //	float t = uni.iTime;

  const int MAX_ITER = 1000;
  const float MAX_DIST = 20.0;
  const float EPSILON = 0.001;

  float3 color = float3(0.1484375, 0.140625, 0.15234375);
  
  // screenPos can range from -1 to 1
  float2 s_pos =  worldCoordAspectAdjusted;
  
  // up vector
  float3 up = float3(0.0, 1.0, 0.0);
  
  // camera position
  float3 c_pos = float3(0.0, 0.0, 8.0);
  // camera target
  float3 c_targ = float3(0.0, 0.0, 0.0);
  // camera direction
  float3 c_dir = normalize(c_targ - c_pos);
  // camera right
  float3 c_right = cross(c_dir, up);
  // camera up
  float3 c_up = cross(c_right, c_dir);
  // camera to screen distance
  //  float c_sdist = 2.0;
  
  // compute the ray direction
  float3 r_dir = normalize(c_dir);
  // ray progress, just begin at the cameras position
  float3 r_prog = c_pos + c_right * s_pos.x + c_up * s_pos.y;
  
  float total_dist = 0.0;
  float dist = EPSILON;
  
  for (int i = 0; i < MAX_ITER; i++)
  {
    if (dist < EPSILON || total_dist > MAX_DIST)
    {
      break;
    }
    
    dist = distfunc(r_prog, uni.iTime);
    total_dist += dist;
    r_prog += dist * r_dir;
  }
  
  if (dist < EPSILON)
  {
    float2 eps = float2(0.0, EPSILON);
    float3 normal = normalize(float3(distfunc(r_prog + eps.yxx, uni.iTime) - distfunc(r_prog - eps.yxx, uni.iTime),
                                     distfunc(r_prog + eps.xyx, uni.iTime) - distfunc(r_prog - eps.xyx, uni.iTime),
                                     distfunc(r_prog + eps.xxy, uni.iTime) - distfunc(r_prog - eps.xxy, uni.iTime)));
    
    float3 l1_col = float3(0.83203125, 0.21875, 0.19921875);
    float3 l1_dir = normalize(float3(4.0, 1.95, -1.0));
    
    float3 l2_col = float3(0.109375, 0.5546875, 0.59375);
    float3 l2_dir = normalize(float3(0.0, -1.0, -0.35));
    
    float3 l3_col = float3(0.8984375, 0.59765625, 0.05078125);
    float3 l3_dir = normalize(float3(-4.0, 1.95, -1.0));
    
    float l1_diffuse = max(0.0, dot(-l1_dir, normal));
    float l1_specular = pow(l1_diffuse, 32.0);
    
    float l2_diffuse = max(0.0, dot(-l2_dir, normal));
    float l2_specular = pow(l2_diffuse, 32.0);
    
    float l3_diffuse = max(0.0, dot(-l3_dir, normal));
    float l3_specular = pow(l3_diffuse, 32.0);
    
    color = (l1_col * (l1_diffuse + l1_specular) +
             l2_col * (l2_diffuse + l2_specular) +
             l3_col * (l3_diffuse + l3_specular));
  }
  
  return float4(color, 1.0);
}
