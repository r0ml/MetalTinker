
#define shaderName linear_motion

#include "Common.h" 

struct InputBuffer {
  float3 velocity;
};

initialize() {
//  in.pipeline._1 = {0, 16, 3, 0};
  in.velocity = {2, 5, 10};
}

frameInitialize() {
  ctrl.vertexCount = 16;
  ctrl.instanceCount = 3;
  ctrl.topology = 0;
}

static float2 dot_pos(float angle, float t, float2 res, uint iid) {
  angle = -angle;
  float z = sin(t - float(iid) * 0.04 - angle*1.5);
  float2 j = (z*z / 1.4 + 0.2)*cos(angle-float2(0,33));
  j = j * res.y/res;
  return (j + 1) / 2.0;
}

static float3 dot_color(float angle) {
  float a=(1 - angle / tau)*6;
  return clamp(float3(abs(a-3)-1, 2-abs(a-2), 2-abs(a-4)), 0, 1);
}

vertexPointFn() {
  VertexOutPoint v;
  v.point_size = uni.iResolution.y / 50; // this is a pixel value, so needs to be adjusted for whether
                    // it is a retina display (static) or not


  float angle = float(vid) / ctrl.instanceCount * tau;
  float t = uni.iTime*2.;

  float2 pos = dot_pos(angle, t, uni.iResolution, iid);

  float3 c = dot_color(angle);
  v.where.xy = 2 * pos - 1;
  v.where.zw = {0, 1};
  v.color = float4(c, 1 - float(iid) * 0.4);

//  float2 uv = 1.3*(2.*thisVertex.where.xy-uni.iResolution)/uni.iResolution.y;
//  float3 col = float3(0);
//  float r = round(fract(atan2(uv.y,uv.x)/TAU) * 16.)/16.;
//  float3 c = dot_color(r);

//  col += c * min(1.,draw_dot(uv,r,t, uni.iResolution)
//                 // Motion blur
//                 + .5 * draw_dot(uv,r,t-.04, uni.iResolution)
//                 + .2 * draw_dot(uv,r,t-.08, uni.iResolution));
  
  return v;
}

// the cananical "make it a circle"
  fragmentPointFn() {
    float2 h = pointCoord;
    if ( distance(h, 0.5) > 0.5) {
      // fragColor.rgb = {1,0,0};
      discard_fragment();
    }
    return thisVertex.color;
  }
