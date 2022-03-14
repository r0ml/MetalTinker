/** 
 Author: luluco250
 This is a work in progress to simulate water
 */

#define shaderName test_water_ripple

#include "Common.h" 

struct InputBuffer {
  bool CORRECT_TEXTURE_SIZE = false;
  bool VIEW_HEIGHT = false;
  bool VIEW_NORMALS = false;
  bool CHEAP_NORMALS = false;
};

initialize() {
}




constant const float TEXTURE_DOWNSCALE = 2.0;


/*static float rand(float2 uv, float t) {
 float seed = dot(uv, float2(12.3435, 25.3746));
 return fract(sin(seed) * 234536.3254 + t);
 }*/

static float2 scale_uv(float2 uv, float2 scale, float2 center) {
  return (uv - center) * scale + center;
}

static float2 scale_uv(float2 uv, float2 scale) {
  return scale_uv(uv, scale, float2(0.5));
}

static float create_ripple(float2 coord, float2 ripple_coord, float scale, float radius, float range, float height) {
  float dist = distance(coord, ripple_coord);
  return sin(dist / scale) * height * smoothstep(dist - range, dist + range, radius);
}

static float2 get_normals(float2 coord, float2 ripple_coord, float scale, float radius, float range, float height) {
  return float2(
                create_ripple(coord + float2(1.0, 0.0), ripple_coord, scale, radius, range, height) -
                create_ripple(coord - float2(1.0, 0.0), ripple_coord, scale, radius, range, height),
                create_ripple(coord + float2(0.0, 1.0), ripple_coord, scale, radius, range, height) -
                create_ripple(coord - float2(0.0, 1.0), ripple_coord, scale, radius, range, height)
                ) * 0.5;
}

static float2 get_center(float2 coord, float t, float2 reso) {
  t = round(t + 0.5);
  return float2(
                .5+.5*sin(t - cos(t + 2354.2345) + 2345.3),
                .5+.5*sin(t + cos(t - 2452.2356) + 1234.0)
                ) * reso;
}

fragmentFn(texture2d<float> tex) {
  float2 ps = float2(1.0) / uni.iResolution.xy;
  float2 uv = textureCoord;

  if (in.CORRECT_TEXTURE_SIZE) {
    float2 tex_size = textureSize(tex);
    uv = scale_uv(uv, (uni.iResolution.xy / tex_size) * float(TEXTURE_DOWNSCALE));
  }

  float timescale = 1.0;
  float t = fract(uni.iTime * timescale);

  float2 center = uni.mouseButtons ? uni.iMouse.xy * uni.iResolution : get_center(thisVertex.where.xy, uni.iTime * timescale, uni.iResolution);

  float2 normals;
  float height = create_ripple( thisVertex.where.xy, center, t * 100.0 + 1.0, 100.0, 200.0, 1000.0);

  if (in.CHEAP_NORMALS ) {
    normals = float2(dfdx(height), dfdy(height));
  } else {
    normals = get_normals( thisVertex.where.xy, center, t * 100.0 + 1.0, 100.0, 200.0, 1000.0);
  }

  if (in.VIEW_HEIGHT) {
    return float4(height);
  } else if ( in.VIEW_NORMALS ) {
    return float4(normals, 0.5, 1.0);
  } else {
    return tex.sample(iChannel0, uv + normals * ps);
  }

  //t = round(uni.iTime) * 20.0;

  //t = uni.iTime;
  //color = float4(rand(uv, t));

}

