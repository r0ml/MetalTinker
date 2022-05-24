/** 
 Author: 0xAA55
 Ray cast to a cylinder example, with uv calculation
 */
#define shaderName a_Cylinder_2

#include "Common.h"

struct InputBuffer {
  };

initialize() {
// setTex(0, asset::london);
}


class shaderName {
public:

float3 eyepos = float3(0.0, 0.0, -5.0);
float2 yawpitch = float2(0, 0);

struct cylinder_t
{
  float3 p;
  float height;
  float radius;
  float3x3 r;
};

float3x3 rot_axis(float3 v, float ang)
{
  float sang = sin(ang);
  float cang = cos(ang);
  return float3x3
  (
   float3
   (
    (1.0 - cang) * v.x * v.x + cang,
    (1.0 - cang) * v.x * v.y - sang * v.z,
    (1.0 - cang) * v.x * v.z + sang * v.y
    ),
   float3
   (
    (1.0 - cang) * v.y * v.x + sang * v.z,
    (1.0 - cang) * v.y * v.y + cang,
    (1.0 - cang) * v.y * v.z - sang * v.x
    ),
   float3
   (
    (1.0 - cang) * v.z * v.x - sang * v.y,
    (1.0 - cang) * v.z * v.y + sang * v.x,
    (1.0 - cang) * v.z * v.z + cang
    )
   );
}

float3x3 rot_yaw_pitch_roll(float3 ypr)
{
  return rotZ(ypr.z) * rotX(ypr.y) * rotY(ypr.x);
}

bool cylinder_raycast(cylinder_t cylinder, float3 orig, float3 dir, thread float3& castpoint, thread float3& normal, thread float2& uv, thread float& intersect_dist, thread bool& isfrominside)
{
  // float3x3 minv = inverse(cylinder.r);
  float3 local_orig = cylinder.r * (orig - cylinder.p);
  float3 local_dir = cylinder.r * dir;
  float r = cylinder.radius;
  float rsq = r * r;
  float hh = cylinder.height / 2.;
  
  bool isinside = false;
  
  float ray_proj = dot(-local_orig.xz, normalize(local_dir.xz));
  float orig_to_axis_dist_sq = dot(local_orig.xz, local_orig.xz);
  float axis_to_ray_sq = max(0., orig_to_axis_dist_sq - ray_proj * ray_proj);
  if(axis_to_ray_sq > rsq) return false;
  float foo = sqrt(rsq - axis_to_ray_sq);
  float dist1 = ray_proj - foo;
  float dist2 = ray_proj + foo;
  if(orig_to_axis_dist_sq < rsq && abs(local_orig.y) <= hh) isinside = true;
  if(isinside && !isfrominside) return false;
  if(isfrominside) intersect_dist = dist2 / length(local_dir.xz);
  else intersect_dist = dist1 / length(local_dir.xz);
  
  float3 local_cast = local_orig + local_dir * intersect_dist;
  float3 local_normal = float3(local_cast.xz, 0.).xzy / r * (isfrominside ? -1.:1.);
  
  if(abs(local_cast.y) > hh)
  {
    float plane1 = (local_orig.y - hh) / (-local_dir.y);
    float plane2 = (local_orig.y + hh) / (-local_dir.y);
    if(isfrominside) intersect_dist = max(plane1, plane2);
    else intersect_dist = min(plane1, plane2);
    local_normal = float3(0, -sign(local_dir.y), 0);
    local_cast = local_orig + local_dir * intersect_dist;
    if(length(local_cast.xz) > r) return false;
    uv = (local_cast.xz + float2(r)) / (r * 2.);
  }
  else
  {
    uv.x = (atan2(local_normal.z, local_normal.x) / PI) * .5 + .5;
    uv.y = (local_cast.y + hh) / cylinder.height;
  }
  
  castpoint = orig + dir * intersect_dist;
  normal = local_normal * cylinder.r;
  isfrominside = isinside;
  
  return true;
}
};

fragmentFn(texture2d<float> tex) {
  shaderName shad;
  
  float2 xy = (thisVertex.where.xy.xy - uni.iResolution.xy * .5) / uni.iResolution.y;
  
  float2 mouse_rotation = (uni.iMouse.xy * 2. -1.) * PI;
  if(length(uni.iMouse.xy) < 0.000001) mouse_rotation = float2(0);
  
  float2 yawpitch = float2(mouse_rotation.x, -mouse_rotation.y);
  float3x3 viewmat = shad.rot_yaw_pitch_roll(float3(yawpitch, 0));
  
  float3x3 rot_m = shad.rot_yaw_pitch_roll(float3(uni.iTime * .3, uni.iTime * .2, uni.iTime * .1));
  
  float3 ray = normalize(float3(xy, 1)) * viewmat;
  float3 eyepos = float3(0., 0., -5.) * viewmat;
  
  float4 color = float4(.2, .5, 1., 1.);
  
  float3 castpnt, castnormal;
  float2 castuv;
  float castdist;
  bool isfrominside = false;
  
  shaderName::cylinder_t cyl = shaderName::cylinder_t { float3(0, 0, 0), 5., 1., rot_m } ;
  
  isfrominside = false;
  // if(xy.x > 0.)isfrominside = true;
  if ( shad.cylinder_raycast(cyl, eyepos, ray, castpnt, castnormal, castuv, castdist, isfrominside))
  {
    // color = float4(castdist - 4.5 + sin(uni.iTime));
    // color = float4(castnormal * .5 + .5, 1.);
    color = tex.sample(iChannel0, castuv);
    // color = texture(iChannel0, castnormal);
    // color = float4(castuv, 0., 1.);
  }
  
  return color;
}
