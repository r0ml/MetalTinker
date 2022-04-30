
#define shaderName Post_Processing_Toon_Shading
#define SHADOWS 2

#include "Common.h"

static float3x3 calcLookAtMatrix(float3 origin, float3 target, float roll) {
  float3 rr = float3(sin(roll), cos(roll), 0.0);
  float3 ww = normalize(target - origin);
  float3 uu = normalize(cross(ww, rr));
  float3 vv = normalize(cross(uu, ww));

  return float3x3(uu, vv, ww);
}

static float3 getRay(float3 origin, float3 target, float2 screenPos, float lensLength) {
  float3x3 camMat = calcLookAtMatrix(origin, target, 0.0);
  return normalize(camMat * float3(screenPos, lensLength));
}

static float2 getDeltas(float2 uv, texture2d<float> rendin0, float2 reso) {
  float2 pixel = float2(1. / reso);
  float3 pole = float3(-1, 0, +1);
  float dpos = 0.0;
  float dnor = 0.0;

  float4 s0 = rendin0.sample(iChannel0, uv + pixel.xy * pole.xx); // x1, y1
  float4 s1 = rendin0.sample(iChannel0, uv + pixel.xy * pole.yx); // x2, y1
  float4 s2 = rendin0.sample(iChannel0, uv + pixel.xy * pole.zx); // x3, y1
  float4 s3 = rendin0.sample(iChannel0, uv + pixel.xy * pole.xy); // x1, y2
                                                                         // float4 s4 = renderInput[0].sample(iChannel0, uv + pixel.xy * pole.yy); // x2, y2
  float4 s5 = rendin0.sample(iChannel0, uv + pixel.xy * pole.zy); // x3, y2
  float4 s6 = rendin0.sample(iChannel0, uv + pixel.xy * pole.xz); // x1, y3
  float4 s7 = rendin0.sample(iChannel0, uv + pixel.xy * pole.yz); // x2, y3
  float4 s8 = rendin0.sample(iChannel0, uv + pixel.xy * pole.zz); // x3, y3

  dpos = (
          abs(s1.a - s7.a) +
          abs(s5.a - s3.a) +
          abs(s0.a - s8.a) +
          abs(s2.a - s6.a)
          ) * 0.5;
  dpos += (
           max(0.0, 1.0 - dot(s1.rgb, s7.rgb)) +
           max(0.0, 1.0 - dot(s5.rgb, s3.rgb)) +
           max(0.0, 1.0 - dot(s0.rgb, s8.rgb)) +
           max(0.0, 1.0 - dot(s2.rgb, s6.rgb))
           );
  
  dpos = pow(max(dpos - 0.5, 0.0), 5.0);

  return float2(dpos, dnor);
}

static float2 mirror(float2 p, float v) {
  float hv = v * 0.5;
  float2  fl = mod(floor(p / v + 0.5), 2.0) * 2.0 - 1.0;
  float2  mp = mod(p + hv, v) - hv;

  return fl * mp;
}

static float map(float3 p, float time, int buttons, float2 mouse, float2 reso ) {
  float r = buttons ? mouse.x * reso.x / 100.0 : time * 0.9;
  p.xz = mirror(p.xz, 4.);
  p.xz = p.xz * rot2d(r);
  float d = sdBox(p, float3(1));
  d = min(d, sdBox(p, float3(0.1, 0.1, 3)));
  d = min(d, sdBox(p, float3(3, 0.1, 0.1)));
  return d;
}

static float calcRayIntersection(float3 rayOrigin, float3 rayDir, float maxd, float precis, float time, int buttons, float2 mouse, float2 reso ) {
  float latest = precis * 2.0;
  float dist   = +0.0;
  // float type   = -1.0;
  float res    = -1.0;

  for (int i = 0; i < 30; i++) {
    if (latest < precis || dist > maxd) break;

    float result = map(rayOrigin + rayDir * dist, time, buttons, mouse, reso);

    latest = result;
    dist  += latest;
  }

  if (dist < maxd) {
    res = dist;
  }

  return res;
}

static float2 squareFrame(float2 screenSize, float2 coord) {
  float2 position = 2.0 * (coord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}

static float3 calcNormal(float3 pos, float eps, float time, int buttons, float2 mouse, float2 reso) {
  const float3 v1 = float3( 1.0,-1.0,-1.0);
  const float3 v2 = float3(-1.0,-1.0, 1.0);
  const float3 v3 = float3(-1.0, 1.0,-1.0);
  const float3 v4 = float3( 1.0, 1.0, 1.0);

  return normalize( v1 * map( pos + v1*eps, time, buttons, mouse, reso ) +
                    v2 * map( pos + v2*eps, time, buttons, mouse, reso ) +
                    v3 * map( pos + v3*eps, time, buttons, mouse, reso ) +
                    v4 * map( pos + v4*eps, time, buttons, mouse, reso ) );
}

static float3 calcNormal(float3 pos, float time, int buttons, float2 mouse, float2 reso) {
  return calcNormal(pos, 0.002, time, buttons, mouse, reso);
}




fragmentFn() {
  FragmentOutput fff;


  // float3 ro = float3(sin(uni.iTime * 0.2), 1.5, cos(uni.iTime * 0.2)) * 5.;
  // float3 ta = float3(0, 0, 0);
  // float3 rd = getRay(ro, ta, squareFrame(uni.iResolution.xy, thisVertex.where.xy), 2.0);
  float2 uv2 = thisVertex.where.xy / uni.iResolution.xy;
  uv2.y = 1 - uv2.y;

  float4 buf = lastFrame[1].sample(iChannel0, uv2);
  float t2 = buf.a;
  float3 nor2 = buf.rgb;
  // float3 pos = ro + rd * t;

  float3 col = float3(0.5, 0.8, 1);
  float2 deltas = getDeltas(uv2, lastFrame[1], uni.iResolution);
  if (t2 > -0.5) {
    col = float3(1.0);
    col *= max(0.3, 0.3 + dot(nor2, normalize(float3(0, 1, 0.5))));
    col *= float3(1, 0.8, 0.35);
  }
  col.r = smoothstep(0.1, 1.0, col.r);
  col.g = smoothstep(0.1, 1.1, col.g);
  col.b = smoothstep(-0.1, 1.0, col.b);
  col = pow(col, float3(1.1));
  col -= deltas.x - deltas.y;

  fff.color0 = float4(col, 1);

  // ============================================== buffers =============================


  float2 uv = squareFrame(uni.iResolution.xy, thisVertex.where.xy);
  float3 ro = float3(sin(uni.iTime * 0.2), 1.5, cos(uni.iTime * 0.2)) * 5.;
  float3 ta = float3(0, 0, 0);
  float3 rd = getRay(ro, ta, uv, 2.0);

  float t = calcRayIntersection(ro, rd, 20.0, 0.001, uni.iTime, uni.wasMouseButtons, uni.iMouse, uni.iResolution);
  float3 pos = ro + rd * t;
  float3 nor = calcNormal(pos, uni.iTime, uni.wasMouseButtons, uni.iMouse, uni.iResolution);

  fff.color1 = float4(nor, t);

  return fff;
}
