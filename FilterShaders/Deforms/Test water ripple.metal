
#define shaderName test_water_ripple

#include "Common.h" 

struct InputBuffer {
  bool VIEW_HEIGHT = false;
  bool VIEW_NORMALS = false;
  bool CHEAP_NORMALS = false;
};

static float create_ripple(float2 coord, float2 ripple_coord, float scale, float radius, float range, float height) {
  float dist = distance(coord, ripple_coord);
  return sin(dist / scale) * height * smoothstep(dist - range, dist + range, radius);
}

static float2 get_normals(float2 coord, float2 ripple_coord, float2 ps, float scale, float radius, float range, float height) {
  return float2(
                create_ripple(coord + float2(ps.x, 0.0), ripple_coord, scale, radius, range, height) -
                create_ripple(coord - float2(ps.x, 0.0), ripple_coord, scale, radius, range, height),
                create_ripple(coord + float2(0.0, ps.y), ripple_coord, scale, radius, range, height) -
                create_ripple(coord - float2(0.0, ps.y), ripple_coord, scale, radius, range, height)
                ) * 0.5;
}

fragmentFunc(texture2d<float> tex, device InputBuffer& in, constant float2& mouse) {
  float2 ps = scn_frame.inverseResolution;
  float2 uv = textureCoord;

  float timescale = 0.5;
  float t = fract(scn_frame.time * timescale);

  float2 center = mouse; //  : get_center(thisVertex.where.xy, uni.iTime * timescale, uni.iResolution);

  float2 normals;
  float height = create_ripple( textureCoord, center, (t * 100.0 + 1.0) / 1000, 100.0 / 1000, 200.0 / 1000, 1000.0 / 1000);

  if (in.CHEAP_NORMALS ) {
    normals = float2(dfdx(height), dfdy(height));
  } else {
    normals = get_normals( textureCoord, center, ps, (t * 100.0 + 1.0) / 1000.0, 100.0 / 1000, 200.0 / 1000, 1000.0 / 1000);
  }

  if (in.VIEW_HEIGHT) {
    return float4(height);
  } else if ( in.VIEW_NORMALS ) {
    return float4(normals, 0.5, 1.0);
  } else {
    return tex.sample(iChannel0, uv + normals );
  }

  //t = round(uni.iTime) * 20.0;

  //t = uni.iTime;
  //color = float4(rand(uv, t));

}

