
#define shaderName a_Cube_6

#include "Common.h"

struct InputBuffer {
    struct {
      int dist = 1;
      int normal;
      int uv;
    } show;
    bool animate = true;

  // not options
//  float3x3 rotation;
//  float3 tracking_rotation;
};

initialize() {
//  setTex(0, asset::london);
//  in.tracking_rotation = 0;
//  in.rotation = float3x3(1);
}

struct box_t {
  float3 p, d;
  float3x3 r;
};

static float3x3 eulerRotation(float3 ypr) {
  return rotZ(ypr.z) * rotX(ypr.y) * rotY(ypr.x);
}

static bool Box_Raycast(box_t box, float3 start, float3 n_ray, thread float3& castpoint, thread float3& normal, thread float2& uv, thread float& castdist, thread bool& isfrominside)
{
  float4x4 box_mat = float4x4
  (
   float4(box.r[0], 0.),
   float4(box.r[1], 0.),
   float4(box.r[2], 0.),
   float4(box.p, 1.)
   );
  bool inside = false;
  
  float4x4 box_mat_inv = inverse(box_mat);
  
  float3 start_local = (box_mat_inv * float4(start, 1.)).xyz;
  float3 ray_local = (box_mat_inv * float4(n_ray, 0.)).xyz;
  
  float3 sv = step(abs(start_local), box.d);
  if(sv.x > .5 && sv.y > .5 && sv.z > .5) inside = true;
  if(inside && !isfrominside) return false;
  if(inside || isfrominside) start_local = -start_local;
  
  float3 rat = 1.0 / ray_local;
  float3 trp = rat * start_local;
  float3 dim = box.d * abs(rat);
  
  float3 t1 = -trp - dim;
  float3 t2 = -trp + dim;
  
  float tN = max( max( t1.x, t1.y ), t1.z );
  float tF = min( min( t2.x, t2.y ), t2.z );
  
  if( tN > tF || (!isfrominside && tF < 0.0) ) return false;
  
  float3 nor = -sign(ray_local)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
  
  castpoint = start + n_ray * tN;
  castdist = abs(tN);
  normal = (box_mat * float4(nor,0.)).xyz;
  isfrominside = inside;
  
  float3 cp_local = (box_mat_inv * float4(castpoint, 1.)).xyz;
  
  uv = (nor.x * cp_local.yz + nor.y * cp_local.zx + nor.z * cp_local.xy) *.5 + .5;
  
  return true;
}

/*computeFn() {
  if (uni.mouseButtons) {
    in.tracking_rotation = PI * float3(  (uni.iMouse - uni.lastTouch) , 0);
  } else if (length(in.tracking_rotation) > 0) {
    in.rotation = rotX( in.tracking_rotation.y ) * rotY(-in.tracking_rotation.x) * in.rotation;
    in.tracking_rotation = 0;
  }

}*/

fragmentFn(texture2d<float> tex) {
  float3 tracking_rotation = uni.mouseButtons ? PI * float3( (uni.iMouse - uni.lastTouch), 0) : 0;

  float3x3 rotation = rotX( tracking_rotation.y ) * rotY( - tracking_rotation.x); // * saved_rotation   ; saved_rotation = 0

  float3 eyepos = float3(0.0, 0.0, -5.0);

  float2 xy = (thisVertex.where.xy - uni.iResolution.xy * .5) / uni.iResolution.y;

  float3 mouse_rotation = tracking_rotation;

  float3x3 RotMat = rotX(mouse_rotation.y) * rotY(-mouse_rotation.x) * rotation * eulerRotation( in.animate * float3(uni.iTime * .2, uni.iTime * .1, uni.iTime * .3));
  
  float3 ray = normalize(float3(xy, 1));
  
  float4 color = float4(.2, .5, 1., 1.);
  
  float3 castpnt, castnormal;
  float2 castuv;
  float castdist;
  bool isfrominside;
  
  box_t bx = box_t { float3(0, 0, 0), float3(1, 1, 1), RotMat } ;
  
  isfrominside = false;
  // if(xy.x > 0.) isfrominside = true;
  if(Box_Raycast(bx, eyepos, ray, castpnt, castnormal, castuv, castdist, isfrominside)) {
    if (in.show.dist) {
      color = float4(castdist);
    } else if (in.show.normal) {
      color = float4(castnormal * .5 + .5, 1.);
    } else if (in.show.uv) {
      color = tex.sample(iChannel0, castuv);
    }
  }
  
  return color;
}

